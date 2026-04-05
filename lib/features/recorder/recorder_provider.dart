import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'models/recording.dart';
import 'models/recording_folder.dart';
import 'repositories/folder_repository.dart';
import 'repositories/recording_repository.dart';

// ── Repositories ─────────────────────────────────────────────
final recordingRepositoryProvider = Provider<RecordingRepository>(
  (_) => RecordingRepository(),
);

final folderRepositoryProvider = Provider<FolderRepository>(
  (_) => FolderRepository(),
);

// ── 資料夾列表 ────────────────────────────────────────────────
final foldersProvider =
    AsyncNotifierProvider<FoldersNotifier, List<RecordingFolder>>(
  FoldersNotifier.new,
);

class FoldersNotifier extends AsyncNotifier<List<RecordingFolder>> {
  FolderRepository get _repo => ref.read(folderRepositoryProvider);

  @override
  Future<List<RecordingFolder>> build() => _repo.loadAll();

  Future<void> add(String name) async {
    final folder = RecordingFolder(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _repo.add(folder);
    state = AsyncData([...state.valueOrNull ?? [], folder]);
  }

  Future<void> rename(String id, String newName) async {
    await _repo.rename(id, newName);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((f) => f.id == id ? f.copyWith(name: newName) : f)
          .toList(),
    );
  }

  Future<void> delete(String id) async {
    await ref.read(recordingRepositoryProvider).deleteByFolderId(id);
    await _repo.delete(id);
    // 只更新自己的 state，不碰 recordingsProvider
    // recording_list.dart 會用 validFolderIds 過濾顯示
    state = AsyncData(
      (state.valueOrNull ?? []).where((f) => f.id != id).toList(),
    );
  }
}

// ── 錄音列表 ─────────────────────────────────────────────────
final recordingsProvider =
    AsyncNotifierProvider<RecordingsNotifier, List<Recording>>(
  RecordingsNotifier.new,
);

class RecordingsNotifier extends AsyncNotifier<List<Recording>> {
  RecordingRepository get _repo => ref.read(recordingRepositoryProvider);

  @override
  Future<List<Recording>> build() => _repo.loadAll();

  Future<void> add(Recording recording) async {
    await _repo.add(recording);
    state = AsyncData([recording, ...state.valueOrNull ?? []]);
  }

  Future<void> rename(String id, String newName) async {
    await _repo.rename(id, newName);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((r) => r.id == id ? r.copyWith(name: newName) : r)
          .toList(),
    );
  }

  Future<void> moveToFolder(String id, String? folderId) async {
    final updated = await _repo.moveToFolder(id, folderId);
    if (updated == null) return;
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((r) => r.id == id ? updated : r)
          .toList(),
    );
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((r) => r.id != id).toList(),
    );
  }
}

// ── 搜尋關鍵字 ───────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((_) => '');

// ── 錄音狀態 ─────────────────────────────────────────────────
enum RecorderStatus { idle, recording }

class RecorderState {
  final RecorderStatus status;
  final int elapsedSeconds;
  final String? pendingPath;
  final String? selectedFolderId;

  const RecorderState({
    this.status = RecorderStatus.idle,
    this.elapsedSeconds = 0,
    this.pendingPath,
    this.selectedFolderId,
  });

  RecorderState copyWith({
    RecorderStatus? status,
    int? elapsedSeconds,
    String? pendingPath,
    String? selectedFolderId,
    bool clearPending = false,
    bool clearFolder = false,
  }) {
    return RecorderState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      pendingPath: clearPending ? null : (pendingPath ?? this.pendingPath),
      selectedFolderId:
          clearFolder ? null : (selectedFolderId ?? this.selectedFolderId),
    );
  }
}

final recorderProvider =
    NotifierProvider<RecorderNotifier, RecorderState>(RecorderNotifier.new);

class RecorderNotifier extends Notifier<RecorderState> {
  final _recorder = AudioRecorder();
  final _uuid = const Uuid();
  bool _timerRunning = false;

  @override
  RecorderState build() => const RecorderState();

  void selectFolder(String? folderId) {
    state = state.copyWith(selectedFolderId: folderId);
  }

  Future<void> startRecording() async {
    final repo = ref.read(recordingRepositoryProvider);
    final id = _uuid.v4();
    final path = await repo.generateRecordingPath(
      id,
      folderId: state.selectedFolderId,
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    state = state.copyWith(
        status: RecorderStatus.recording, elapsedSeconds: 0);
    _startTimer();
  }

  Future<void> stopRecording() async {
    _stopTimer();
    final path = await _recorder.stop();
    if (path == null) return;
    state = state.copyWith(
      status: RecorderStatus.idle,
      pendingPath: path,
    );
  }

  Future<void> saveRecording(String name) async {
    final path = state.pendingPath;
    if (path == null) return;
    if (!await File(path).exists()) return;

    final id = path.split('/').last.replaceAll('.m4a', '');
    final recording = Recording(
      id: id,
      name: name,
      path: path,
      durationSeconds: state.elapsedSeconds,
      createdAt: DateTime.now(),
      folderId: state.selectedFolderId,
    );

    await ref.read(recordingsProvider.notifier).add(recording);
    state = RecorderState(selectedFolderId: state.selectedFolderId);
  }

  Future<void> discardRecording() async {
    final path = state.pendingPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    state = RecorderState(selectedFolderId: state.selectedFolderId);
  }

  Future<void> shareRecording(Recording recording) async {
    await Share.shareXFiles(
      [XFile(recording.path)],
      text: recording.name,
    );
  }

  void _startTimer() {
    _timerRunning = true;
    _tick();
  }

  void _stopTimer() => _timerRunning = false;

  Future<void> _tick() async {
    while (_timerRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_timerRunning) break;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    }
  }

  void dispose() {
    _stopTimer();
    _recorder.dispose();
  }
}

// ── 播放狀態 ─────────────────────────────────────────────────
final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, String?>(AudioPlayerNotifier.new);

class AudioPlayerNotifier extends Notifier<String?> {
  final _player = AudioPlayer();

  @override
  String? build() => null;

  AudioPlayer get player => _player;

  Future<void> play(Recording recording) async {
    if (state == recording.id) {
      await _player.stop();
      state = null;
      return;
    }
    await _player.stop();
    await _player.setFilePath(recording.path);
    await _player.play();
    state = recording.id;

    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        state = null;
      }
    });
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
    state = null;
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void dispose() {
    _player.dispose();
  }
}
