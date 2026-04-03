library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:buffered_list_stream/buffered_list_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/utils/music_utils.dart';

/// 調音器的狀態
class TunerState {
  /// 目前偵測到的音高資訊
  final PitchInfo? pitchInfo;

  /// 是否正在聆聽
  final bool isListening;

  /// 錯誤訊息
  final String? error;

  /// 調音基準音高（Hz），預設 440
  final double referenceA4;

  /// 目前選擇的樂器
  final Instrument selectedInstrument;

  const TunerState({
    this.pitchInfo,
    this.isListening = false,
    this.error,
    this.referenceA4 = AppConstants.standardPitch,
    this.selectedInstrument = Instruments.concertPitch,
  });

  TunerState copyWith({
    PitchInfo? pitchInfo,
    bool? isListening,
    String? error,
    double? referenceA4,
    Instrument? selectedInstrument,
    bool clearPitch = false,
  }) {
    return TunerState(
      pitchInfo: clearPitch ? null : (pitchInfo ?? this.pitchInfo),
      isListening: isListening ?? this.isListening,
      error: error ?? this.error,
      referenceA4: referenceA4 ?? this.referenceA4,
      selectedInstrument: selectedInstrument ?? this.selectedInstrument,
    );
  }
}

/// 調音器 Notifier
class TunerNotifier extends StateNotifier<TunerState> {
  TunerNotifier() : super(const TunerState());

  final _recorder = AudioRecorder();
  final _pitchDetector = PitchDetector(
    audioSampleRate: PitchDetector.DEFAULT_SAMPLE_RATE.toDouble(),
    bufferSize: PitchDetector.DEFAULT_BUFFER_SIZE,
  );
  StreamSubscription? _audioSubscription;

  /// 開始偵測音高
  Future<void> startListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        state = state.copyWith(error: '需要麥克風權限才能使用調音器');
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(isListening: true, error: null);
    }

    final recordStream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: 1,
        sampleRate: PitchDetector.DEFAULT_SAMPLE_RATE.toInt(),
      ),
    );

    final audioSampleBufferedStream = bufferedListStream(
      recordStream.map((event) => event.toList()),
      PitchDetector.DEFAULT_BUFFER_SIZE * 2,
    );

    _audioSubscription = audioSampleBufferedStream.listen((audioSample) async {
      if (!mounted) return;

      final intBuffer = Uint8List.fromList(audioSample);
      final result = await _pitchDetector.getPitchFromIntBuffer(intBuffer);

      if (!mounted) return;

      if (result.pitched) {
        final pitchInfo = MusicUtils.frequencyToPitch(
          result.pitch,
          a4Reference: state.referenceA4,
          // 套用目前選擇的樂器移調
          transposeSteps: state.selectedInstrument.transposeSteps,
        );
        state = state.copyWith(pitchInfo: pitchInfo);
      } else {
        state = state.copyWith(clearPitch: true);
      }
    });
  }

  /// 停止偵測音高
  Future<void> stopListening() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
    if (mounted) {
      state = state.copyWith(isListening: false, clearPitch: true);
    }
  }

  /// 更新調音基準音高
  void setReferenceA4(double pitch) {
    if (mounted) {
      state = state.copyWith(referenceA4: pitch);
    }
  }

  /// 更新選擇的樂器
  void setInstrument(Instrument instrument) {
    if (mounted) {
      state = state.copyWith(
        selectedInstrument: instrument,
        clearPitch: true,
      );
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _recorder.stop();
    super.dispose();
  }
}

/// 調音器 Provider
final tunerProvider =
    StateNotifierProvider<TunerNotifier, TunerState>((ref) {
  return TunerNotifier();
});