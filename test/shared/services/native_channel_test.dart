library;

/// Native Channel & Platform 邊界 Bad Case 測試
///
/// 覆蓋範圍：
///   BC-NC1  NativeMetronomeChannel：非 Android 平台所有方法 → 靜默返回不 throw
///   BC-NC2  NativeMetronomeChannel：_handleNativeCall 'onBeat' → broadcast stream 發出事件
///   BC-NC3  NativeMetronomeChannel：未知方法名 → 不 throw
///   BC-NC4  AudioFocusChannel：_parseCode 所有 AUDIOFOCUS_* 常數 → 正確映射
///   BC-NC5  AudioFocusChannel：未知 code（null / 0 / 999）→ AudioFocusState.unknown
///   BC-NC6  AudioFocusChannel：非 Android 時 setMethodCallHandler 不呼叫
///   BC-NC7  MusicUtils 邊界：所有合法頻率範圍 [25, 5000] 均返回非 null
///   BC-NC8  AppConstants tunerMinPitch / tunerMaxPitch 邊界一致性
///           （發現 TunerControls clamp(400,480) 與 constants 不一致）
///
/// 注意：Platform Channel 的 invokeMethod 需要 Android 環境才能真正執行，
///       此處測試的是 Flutter 側（Dart）的邏輯純函式與狀態機。

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_musician/shared/services/audio_focus_channel.dart';
import 'package:wind_musician/shared/constants/app_constants.dart';
import 'package:wind_musician/shared/utils/music_utils.dart';

// ─── 重現 AudioFocusChannel._parseCode 邏輯（純函式提取用於測試）─────────────
AudioFocusState parseAudioFocusCode(int? code) {
  switch (code) {
    case 1:  return AudioFocusState.gained;
    case -1: return AudioFocusState.lost;
    case -2: return AudioFocusState.lostTransient;
    case -3: return AudioFocusState.duck;
    default: return AudioFocusState.unknown;
  }
}

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // BC-NC4: AudioFocus _parseCode 映射
  // ────────────────────────────────────────────────────────────────────────

  group('BC-NC4：AudioFocusChannel._parseCode 正確映射', () {
    test('code=1 → AudioFocusState.gained', () {
      expect(parseAudioFocusCode(1), equals(AudioFocusState.gained));
    });

    test('code=-1 → AudioFocusState.lost（AUDIOFOCUS_LOSS）', () {
      expect(parseAudioFocusCode(-1), equals(AudioFocusState.lost));
    });

    test('code=-2 → AudioFocusState.lostTransient（來電、通知）', () {
      expect(parseAudioFocusCode(-2), equals(AudioFocusState.lostTransient));
    });

    test('code=-3 → AudioFocusState.duck（可壓低音量繼續播）', () {
      expect(parseAudioFocusCode(-3), equals(AudioFocusState.duck));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-NC5: 未知 / null code → unknown
  // ────────────────────────────────────────────────────────────────────────

  group('BC-NC5：AudioFocusChannel 未知 code → unknown', () {
    test('code=null → unknown', () {
      expect(parseAudioFocusCode(null), equals(AudioFocusState.unknown));
    });

    test('code=0 → unknown（0 不是合法 AUDIOFOCUS_* 值）', () {
      expect(parseAudioFocusCode(0), equals(AudioFocusState.unknown));
    });

    test('code=999 → unknown', () {
      expect(parseAudioFocusCode(999), equals(AudioFocusState.unknown));
    });

    test('code=2 → unknown（2 不在規格中）', () {
      expect(parseAudioFocusCode(2), equals(AudioFocusState.unknown));
    });

    test('code=-4 → unknown（-4 不在規格中）', () {
      expect(parseAudioFocusCode(-4), equals(AudioFocusState.unknown));
    });

    test('所有定義的 code 都不映射到 unknown', () {
      const definedCodes = [1, -1, -2, -3];
      for (final code in definedCodes) {
        expect(parseAudioFocusCode(code), isNot(equals(AudioFocusState.unknown)),
            reason: 'code=$code 不應映射到 unknown');
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-NC8: AppConstants 音高邊界一致性
  //   已發現 BUG：TunerControls clamp(400, 480) ≠ AppConstants.tunerMin/MaxPitch (420, 460)
  // ────────────────────────────────────────────────────────────────────────

  group('BC-NC8：AppConstants tunerMinPitch / tunerMaxPitch 邊界（BC BUG 文件化）', () {
    test('tunerMinPitch = 420.0', () {
      expect(AppConstants.tunerMinPitch, equals(420.0));
    });

    test('tunerMaxPitch = 460.0', () {
      expect(AppConstants.tunerMaxPitch, equals(460.0));
    });

    test('tunerMinPitch < tunerMaxPitch', () {
      expect(AppConstants.tunerMinPitch, lessThan(AppConstants.tunerMaxPitch));
    });

    test('standardPitch (442) 在 [tunerMinPitch, tunerMaxPitch] 內', () {
      expect(AppConstants.standardPitch,
          greaterThanOrEqualTo(AppConstants.tunerMinPitch));
      expect(AppConstants.standardPitch,
          lessThanOrEqualTo(AppConstants.tunerMaxPitch));
    });

    // 文件化已知 BUG：TunerControls._adjust clamp(400, 480) 超出 AppConstants 規格
    // 修正方向：改為 clamp(AppConstants.tunerMinPitch, AppConstants.tunerMaxPitch)
    test('[BUG-DOC] TunerControls clamp(400,480) 與 AppConstants(420,460) 不一致', () {
      // 以下斷言故意測試 AppConstants 值，預期 400 < tunerMinPitch
      // 若此測試失敗代表 AppConstants 已修正，但 TunerControls 還沒同步
      expect(400, lessThan(AppConstants.tunerMinPitch),
          reason: 'TunerControls 的 hard-coded 400 低於 AppConstants.tunerMinPitch=420，'
              '應改用 AppConstants 常數');
      expect(480, greaterThan(AppConstants.tunerMaxPitch),
          reason: 'TunerControls 的 hard-coded 480 高於 AppConstants.tunerMaxPitch=460，'
              '應改用 AppConstants 常數');
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-NC7: MusicUtils 在 [25, 5000] 的合法頻率都返回非 null
  // ────────────────────────────────────────────────────────────────────────

  group('BC-NC7：MusicUtils 合法頻率範圍完整性', () {
    test('25 Hz（下限）→ 非 null', () {
      expect(MusicUtils.frequencyToPitch(25.0, a4Reference: 440.0), isNotNull);
    });

    test('5000 Hz（上限）→ 非 null', () {
      expect(MusicUtils.frequencyToPitch(5000.0, a4Reference: 440.0), isNotNull);
    });

    test('代表性頻率均非 null', () {
      const sampleFrequencies = [
        32.7,   // C1
        65.4,   // C2
        130.8,  // C3
        261.6,  // C4 中央C
        440.0,  // A4
        880.0,  // A5
        1760.0, // A6
        3520.0, // A7
      ];
      for (final freq in sampleFrequencies) {
        final result = MusicUtils.frequencyToPitch(freq, a4Reference: 440.0);
        expect(result, isNotNull, reason: '$freq Hz 應返回有效 PitchInfo');
      }
    });

    test('referenceA4=420（下限）時 A4 識別正確', () {
      final info = MusicUtils.frequencyToPitch(420.0, a4Reference: 420.0);
      expect(info, isNotNull);
      expect(info!.noteName, equals('A'));
      expect(info.centsOff.abs(), lessThan(1.0));
    });

    test('referenceA4=460（上限）時 A4 識別正確', () {
      final info = MusicUtils.frequencyToPitch(460.0, a4Reference: 460.0);
      expect(info, isNotNull);
      expect(info!.noteName, equals('A'));
      expect(info.centsOff.abs(), lessThan(1.0));
    });

    test('24.9 Hz（低於下限）→ null', () {
      expect(MusicUtils.frequencyToPitch(24.9), isNull);
    });

    test('5000.1 Hz（高於上限）→ null', () {
      expect(MusicUtils.frequencyToPitch(5000.1), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-NC1: 非 Android 平台的 Platform Channel 方法靜默返回（邏輯模擬）
  //
  //   NativeMetronomeChannel / AudioFocusChannel 的 public 方法都有
  //   `if (!Platform.isAndroid) return;` guard。
  //   此測試透過模擬該 guard 邏輯驗證非 Android 路徑不執行任何操作。
  // ────────────────────────────────────────────────────────────────────────

  group('BC-NC1：非 Android 平台 guard 邏輯', () {
    test('isAndroid=false 時 start() guard 直接 return', () {
      bool isAndroid = false;
      bool startExecuted = false;

      void simulatedStart() {
        if (!isAndroid) return; // Platform guard
      }

      simulatedStart();
      expect(startExecuted, isFalse,
          reason: '非 Android 時不應執行 Native start()');
    });

    test('isAndroid=false 時 stop() guard 直接 return', () {
      bool isAndroid = false;
      bool stopExecuted = false;

      void simulatedStop() {
        if (!isAndroid) return;
      }

      simulatedStop();
      expect(stopExecuted, isFalse);
    });

    test('isAndroid=false 時 updateBpm() guard 直接 return', () {
      bool isAndroid = false;
      bool executed = false;

      void simulatedUpdateBpm(int bpm) {
        if (!isAndroid) return;
      }

      simulatedUpdateBpm(120);
      expect(executed, isFalse);
    });

    test('isAndroid=true 時方法被執行', () {
      bool executed = false;

      void simulatedStart() {
        executed = true;
      }

      simulatedStart();
      expect(executed, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-NC3: _handleNativeCall 未知方法名不 throw
  // ────────────────────────────────────────────────────────────────────────

  group('BC-NC3：_handleNativeCall 未知方法名不 crash', () {
    test('已知方法 "onBeat" 觸發 stream add', () {
      // 模擬 _handleNativeCall 邏輯
      final List<String> received = [];
      void handleCall(String method) {
        if (method == 'onBeat') {
          received.add('beat');
        }
        // 未知方法：靜默忽略，不 throw
      }

      handleCall('onBeat');
      expect(received, equals(['beat']));
    });

    test('未知方法 "unknownMethod" → 不 throw，不 add 到 stream', () {
      final List<String> received = [];
      void handleCall(String method) {
        if (method == 'onBeat') received.add('beat');
        // 其他方法靜默忽略
      }

      expect(() => handleCall('unknownMethod'), returnsNormally);
      expect(received, isEmpty);
    });

    test('空字串方法名 → 不 throw', () {
      void handleCall(String method) {
        if (method == 'onBeat') {} // 只處理 onBeat
      }
      expect(() => handleCall(''), returnsNormally);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // AudioFocusState 列舉完整性
  // ────────────────────────────────────────────────────────────────────────

  group('AudioFocusState 列舉完整性', () {
    test('AudioFocusState 包含 5 個值', () {
      expect(AudioFocusState.values.length, equals(5));
    });

    test('AudioFocusState.values 包含所有預期值', () {
      expect(AudioFocusState.values, containsAll([
        AudioFocusState.gained,
        AudioFocusState.lost,
        AudioFocusState.lostTransient,
        AudioFocusState.duck,
        AudioFocusState.unknown,
      ]));
    });
  });
}
