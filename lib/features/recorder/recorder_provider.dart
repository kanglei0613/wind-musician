import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../shared/constants/app_constants.dart';
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
  /// BC-011 / BC-002：操作失敗時的錯誤訊息，UI 顯示後應呼叫 clearError
  final String? error;

  const RecorderState({
    this.status = RecorderStatus.idle,
    this.elapsedSeconds = 0,
    this.pendingPath,
    this.selectedFolderId,
    this.error,
  });

  RecorderState copyWith({
    RecorderStatus? status,
    int? elapsedSeconds,
    String? pendingPath,
    String? selectedFolderId,
    bool clearPending = false,
    bool clearFolder = false,
    String? error,
    bool clearError = false,
  }) {
    return RecorderState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      pendingPath: clearPending ? null : (pendingPath ?? this.pendingPath),
      selectedFolderId:
          clearFolder ? null : (selectedFolderId ?? this.selectedFolderId),
      error: clearError ? null : (error ?? this.error),
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
  RecorderState build() {
    // ref.onDispose 確保 Riverpod 在 provider 被移除時正確釋放資源
    ref.onDispose(() {
      _timerRunning = false;
      _recorder.dispose();
    });
    return const RecorderState();
  }

  void selectFolder(String? folderId) {
    state = state.copyWith(selectedFolderId: folderId);
  }

  Future<void> startRecording() async {
    // 先確認麥克風權限，避免 Android 13+ PlatformException crash
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      // 權限拒絕：不進行錄音，UI 層可透過 recorderProvider 的 status 判斷
      return;
    }

    final repo = ref.read(recordingRepositoryProvider);
    final id = _uuid.v4();
    final path = await repo.generateRecordingPath(
      id,
      folderId: state.selectedFolderId,
    );

    // BC-002：_recorder.start 失敗（硬體異常、路徑錯誤等）時 reset 狀態
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecorderStatus.idle,
        error: '錄音啟動失敗，請重試。',
      );
      return;
    }

    state = state.copyWith(
        status: RecorderStatus.recording, elapsedSeconds: 0, clearError: true);
    _startTimer();
  }

  Future<void> stopRecording() async {
    // Re-entry guard：若已非錄音狀態（例如 _tick 與 UI 同時觸發）直接返回，
    // 避免 _recorder.stop() 被呼叫兩次而拋出 PlatformException
    if (state.status != RecorderStatus.recording) return;

    _stopTimer();
    // 在第一個 await 前即時將 status 改為 idle，
    // 確保空窗期內任何重複呼叫都會被上方 guard 攔截
    state = state.copyWith(status: RecorderStatus.idle);

    final path = await _recorder.stop();
    // BC-011：path 為 null 表示平台未回傳路徑，提示用戶而非靜默遺失
    if (path == null) {
      state = state.copyWith(error: '錄音儲存失敗，請重試。');
      return;
    }
    state = state.copyWith(pendingPath: path);
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
      final next = state.elapsedSeconds + 1;
      state = state.copyWith(elapsedSeconds: next);
      // 達到上限自動停止，並透過 pendingPath 觸發儲存對話框
      if (next >= AppConstants.maxRecordingSeconds) {
        await stopRecording();
        break;
      }
    }
  }
}

// ── 播放狀態 ─────────────────────────────────────────────────
final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, String?>(AudioPlayerNotifier.new);

class AudioPlayerNotifier extends Notifier<String?> {
  final _player = AudioPlayer();
  // 保存 subscription，每次 play() 前先取消，避免累積洩漏
  StreamSubscription? _stateSubscription;

  @override
  String? build() {
    // ref.onDispose 確保 Riverpod 在 provider 被移除時正確釋放資源
    ref.onDispose(() {
      _stateSubscription?.cancel();
      _player.dispose();
    });
    return null;
  }

  AudioPlayer get player => _player;

  Future<void> play(Recording recording) async {
    if (state == recording.id) {
      await _player.stop();
      state = null;
      return;
    }
    // 取消上一次的 subscription，再建立新的
    await _stateSubscription?.cancel();
    _stateSubscription = null;

    await _player.stop();
    // BC-003：setFilePath / play 可能因檔案不存在或已刪除而 crash
    try {
      await _player.setFilePath(recording.path);
      await _player.play();
    } catch (e) {
      state = null;
      rethrow; // UI 層 catch 後顯示 SnackBar
    }
    state = recording.id;

    _stateSubscription = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        state = null;
      }
    });
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _player.stop();
    state = null;
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
}
