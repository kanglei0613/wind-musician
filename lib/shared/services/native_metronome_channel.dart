import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// NativeMetronomeChannel
///
/// Android + iOS 原生節拍器服務的 Flutter 端 Platform Channel 封裝（Singleton）。
///
/// 職責：
///   - 提供 start / stop / updateBpm / updateTimeSig 等控制方法
///   - 監聽來自 Native 的 "onBeat" 事件，轉發給訂閱者
///
/// 架構說明：
///   - Android 與 iOS 均使用此 Channel 通訊；其他平台（桌面等）直接忽略
///   - 使用 Singleton 確保整個 App 只有一個 Channel 實例
///   - 呼叫者透過 [onBeat] Stream 訂閱拍點事件，無需關心 Platform Channel 細節
class NativeMetronomeChannel {
  // ── Singleton ───────────────────────────────────────────────────────────
  static final NativeMetronomeChannel _instance =
      NativeMetronomeChannel._internal();

  factory NativeMetronomeChannel() => _instance;

  NativeMetronomeChannel._internal() {
    if (Platform.isAndroid || Platform.isIOS) {
      // 設定 MethodChannel handler 接收 Native → Flutter 的呼叫（Android + iOS）
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  // ── Platform Channel ────────────────────────────────────────────────────
  static const _channel =
      MethodChannel('com.kanglei.muklang/metronome');

  // ── Beat 事件 Stream ────────────────────────────────────────────────────
  /// 每拍觸發一次的 broadcast Stream。
  /// 訂閱此 Stream 的 Widget 可據此更新節拍動畫、計算拍位等。
  final _beatController = StreamController<void>.broadcast();

  Stream<void> get onBeat => _beatController.stream;

  // ── 公開控制方法 ────────────────────────────────────────────────────────

  /// 啟動節拍器前景服務。
  ///
  /// @param bpm         BPM（每分鐘拍數）
  /// @param numerator   拍號分子（每小節拍數）
  /// @param denominator 拍號分母（幾分音符為一拍）
  Future<void> start({
    required int bpm,
    required int numerator,
    required int denominator,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // BC-004：invokeMethod 可能因 Native 服務異常拋出 PlatformException
    try {
      await _channel.invokeMethod<void>('start', {
        'bpm': bpm,
        'numerator': numerator,
        'denominator': denominator,
      });
    } on PlatformException catch (e) {
      throw Exception('節拍器啟動失敗：${e.message}');
    }
  }

  /// 停止節拍器並釋放前景服務。
  Future<void> stop() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // BC-004：stop 亦可能拋出 PlatformException（例如服務已意外終止）
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (e) {
      throw Exception('節拍器停止失敗：${e.message}');
    }
  }

  /// 動態更新 BPM（播放中可呼叫，不中斷播放）。
  Future<void> updateBpm(int bpm) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // BC-004：updateBpm 亦可能拋出 PlatformException
    try {
      await _channel.invokeMethod<void>('updateBpm', {'bpm': bpm});
    } on PlatformException catch (e) {
      throw Exception('BPM 更新失敗：${e.message}');
    }
  }

  /// 動態更新拍號（播放中可呼叫）。
  Future<void> updateTimeSig(int numerator, int denominator) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // BC-004：updateTimeSig 亦可能拋出 PlatformException
    try {
      await _channel.invokeMethod<void>('updateTimeSig', {
        'numerator': numerator,
        'denominator': denominator,
      });
    } on PlatformException catch (e) {
      throw Exception('拍號更新失敗：${e.message}');
    }
  }

  /// 切換音色（播放中也可呼叫，Android 端在 audioThread 熱替換 AudioTrack）。
  ///
  /// @param soundType  "SINE" | "WOODBLOCK" | "STICK_CLICK" | "SNARE"
  Future<void> setSoundType(String soundType) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('setSoundType', {'sound': soundType});
    } on PlatformException catch (e) {
      throw Exception('音色切換失敗：${e.message}');
    }
  }

  /// 切換音高變體（1~5，1 最低、5 最高）。
  Future<void> setPitchVariant(int variant) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('setPitchVariant', {'variant': variant});
    } on PlatformException catch (e) {
      throw Exception('音高變體切換失敗：${e.message}');
    }
  }

  // ── 內部處理 ────────────────────────────────────────────────────────────

  /// 接收來自 Native 的方法呼叫。
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onBeat') {
      // Native 打了一拍 → 廣播給所有訂閱者
      _beatController.add(null);
    }
    return null;
  }

  /// 釋放資源（通常不需要呼叫，Singleton 會持續存活）。
  void dispose() {
    _beatController.close();
  }
}
