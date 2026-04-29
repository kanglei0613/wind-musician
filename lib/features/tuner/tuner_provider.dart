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
    // 避免重複啟動
    if (state.isListening) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        if (status.isPermanentlyDenied) {
          // 永久拒絕：提示用戶前往設定，並自動開啟設定頁
          state = state.copyWith(
            error: '麥克風權限已被永久拒絕，請前往設定 → 隱私權 → 麥克風，開啟 Wind Musician 的存取權限。',
          );
          await openAppSettings();
        } else {
          state = state.copyWith(error: '需要麥克風權限才能使用調音器');
        }
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(isListening: true, error: null);
    }

    // BC-001：startStream 可能因硬體故障或麥克風被搶占而拋出例外
    final Stream<Uint8List> recordStream;
    try {
      recordStream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          sampleRate: PitchDetector.DEFAULT_SAMPLE_RATE.toInt(),
        ),
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isListening: false,
          error: '無法啟動麥克風，請確認權限並重試。',
        );
      }
      return;
    }

    final audioSampleBufferedStream = bufferedListStream(
      recordStream.map((event) => event.toList()),
      // bufferSize 加大，低頻偵測更準確
      4096 * 2,
    );

    _audioSubscription = audioSampleBufferedStream.listen(
      (audioSample) async {
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
      },
      onError: (Object error) {
        // stream 出錯時（硬體故障、背景切換等）更新狀態，避免 UI 卡在「聆聽中」
        if (mounted) {
          state = state.copyWith(
            isListening: false,
            error: '音訊串流發生錯誤，請重新開啟調音器。',
            clearPitch: true,
          );
        }
      },
      cancelOnError: true,
    );
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
