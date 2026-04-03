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
  final PitchInfo? pitchInfo;
  final bool isListening;
  final String? error;
  final double referenceA4;
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
    bufferSize: 4096,
  );
  StreamSubscription? _audioSubscription;

  /// 連續沒有偵測到音高的次數
  int _noSignalCount = 0;

  /// 連續幾次沒偵測到才清空顯示（避免短暫中斷造成閃爍）
  static const _noSignalThreshold = 8;

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
      // bufferSize 加大，低頻偵測更準確
      4096 * 2,
    );

    _audioSubscription = audioSampleBufferedStream.listen((audioSample) async {
      if (!mounted) return;

      final intBuffer = Uint8List.fromList(audioSample);
      final result = await _pitchDetector.getPitchFromIntBuffer(intBuffer);

      if (!mounted) return;

      // probability > 0.9 才視為可靠的音高偵測
      if (result.pitched && result.probability > 0.9) {
        _noSignalCount = 0;
        final pitchInfo = MusicUtils.frequencyToPitch(
          result.pitch,
          a4Reference: state.referenceA4,
          transposeSteps: state.selectedInstrument.transposeSteps,
        );
        state = state.copyWith(pitchInfo: pitchInfo);
      } else {
        _noSignalCount++;
        // 連續 8 次沒偵測到才清空，避免短暫中斷閃爍
        if (_noSignalCount >= _noSignalThreshold) {
          state = state.copyWith(clearPitch: true);
        }
      }
    });
  }

  Future<void> stopListening() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
    if (mounted) {
      state = state.copyWith(isListening: false, clearPitch: true);
    }
  }

  void setReferenceA4(double pitch) {
    if (mounted) {
      state = state.copyWith(referenceA4: pitch);
    }
  }

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

final tunerProvider =
    StateNotifierProvider<TunerNotifier, TunerState>((ref) {
  return TunerNotifier();
});
