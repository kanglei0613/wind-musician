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
  /// true 表示麥克風權限已被拒絕且 iOS 不會再顯示系統對話框，
  /// UI 層應顯示「前往設定」按鈕讓使用者手動開啟。
  final bool micPermPermanentlyDenied;
  final double referenceA4;
  final Instrument selectedInstrument;

  const TunerState({
    this.pitchInfo,
    this.isListening = false,
    this.error,
    this.micPermPermanentlyDenied = false,
    this.referenceA4 = AppConstants.standardPitch,
    this.selectedInstrument = Instruments.concertPitch,
  });

  TunerState copyWith({
    PitchInfo? pitchInfo,
    bool? isListening,
    String? error,
    bool? micPermPermanentlyDenied,
    double? referenceA4,
    Instrument? selectedInstrument,
    bool clearPitch = false,
    bool clearError = false,
  }) {
    return TunerState(
      pitchInfo: clearPitch ? null : (pitchInfo ?? this.pitchInfo),
      isListening: isListening ?? this.isListening,
      error: clearError ? null : (error ?? this.error),
      micPermPermanentlyDenied:
          micPermPermanentlyDenied ?? this.micPermPermanentlyDenied,
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

  /// 防止權限請求與 startListening 重複執行的鎖
  bool _isRequesting = false;

  Future<void> startListening() async {
    // 避免重複啟動：isListening 已在串流中，或 _isRequesting 正在等待系統對話框
    if (state.isListening || _isRequesting) return;
    _isRequesting = true;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          if (status.isPermanentlyDenied) {
            // 權限已永久拒絕：直接開啟系統設定，不顯示中間警告
            openAppSettings();
          } else {
            state = state.copyWith(
              error: '需要麥克風權限才能使用調音器',
              micPermPermanentlyDenied: false,
            );
          }
        }
        return;
      }
    } finally {
      _isRequesting = false;
    }

    if (mounted) {
      state = state.copyWith(
        isListening: true,
        clearError: true,
        micPermPermanentlyDenied: false,
      );
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

        // probability > 0.75 才視為可靠的音高偵測（較低門檻，提升靈敏度）
        if (result.pitched && result.probability > 0.75) {
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
