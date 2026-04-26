import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// AudioFocus 狀態枚舉
///
/// 對應 Android AudioManager 的 AUDIOFOCUS_* 常數。
/// Flutter 側用此枚舉更新 UI，不直接使用 Android 數字常數。
enum AudioFocusState {
  /// 取得或恢復焦點（AUDIOFOCUS_GAIN = 1）
  gained,

  /// 永久失去焦點（AUDIOFOCUS_LOSS = -1），例如音樂 App 啟動
  lost,

  /// 短暫失去焦點（AUDIOFOCUS_LOSS_TRANSIENT = -2），例如來電
  lostTransient,

  /// 可壓低音量繼續播放（AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK = -3）
  duck,

  /// 未知狀態（預設）
  unknown,
}

/// AudioFocusChannel
///
/// Android AudioFocus 事件的 Flutter 端 Platform Channel 封裝（Singleton）。
///
/// 用途：
///   當螢幕錄影工具（如 AZ Screen Recorder）或其他音訊 App 搶走焦點時，
///   此 Channel 接收 Native 的通知，Flutter UI 可據此：
///     - 顯示「音訊焦點被搶走，請關閉錄影工具後重啟」的提示
///     - 自動暫停節拍器 UI 狀態（音效已由 MetronomeService 停止）
class AudioFocusChannel {
  // ── Singleton ───────────────────────────────────────────────────────────
  static final AudioFocusChannel _instance = AudioFocusChannel._internal();

  factory AudioFocusChannel() => _instance;

  AudioFocusChannel._internal() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  // ── Platform Channel ────────────────────────────────────────────────────
  static const _channel =
      MethodChannel('com.kanglei.wind_musician/audio_focus');

  // ── Focus 狀態 Stream ────────────────────────────────────────────────────
  final _focusController = StreamController<AudioFocusState>.broadcast();

  /// 訂閱 AudioFocus 狀態變化。
  /// 每次 Android 的 OnAudioFocusChangeListener 觸發就會發出新事件。
  Stream<AudioFocusState> get onFocusChange => _focusController.stream;

  // ── 內部處理 ────────────────────────────────────────────────────────────

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onFocusChange') {
      final code = call.arguments as int?;
      final state = _parseCode(code);
      _focusController.add(state);
    }
    return null;
  }

  /// 將 Android AUDIOFOCUS_* 整數常數轉換為 [AudioFocusState] 枚舉。
  AudioFocusState _parseCode(int? code) {
    switch (code) {
      case 1:  return AudioFocusState.gained;       // AUDIOFOCUS_GAIN
      case -1: return AudioFocusState.lost;         // AUDIOFOCUS_LOSS
      case -2: return AudioFocusState.lostTransient; // AUDIOFOCUS_LOSS_TRANSIENT
      case -3: return AudioFocusState.duck;         // AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK
      default: return AudioFocusState.unknown;
    }
  }

  void dispose() {
    _focusController.close();
  }
}
