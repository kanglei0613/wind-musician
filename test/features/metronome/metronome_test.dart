library;

/// 節拍器 Bad Case 測試
///
/// 覆蓋範圍：
///   BC-M1  長按 +/− 後手指滑出時 onLongPressCancel 應停止 timer
///   BC-M2  BPM 輸入邊界：最小值、最大值、超出範圍、非數字字串
///   BC-M3  分母只允許 [1,2,4,8,16,32]
///   BC-M5  _scheduleNextBeat 計算：BPM=20/60/120/320 的 intervalMs
///   BC-M6  Section 切換：_currentSectionIndex 循環回 0
///   BC-M7  _onBeat beat 計數：達到 numerator 時重置為 0

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_musician/shared/constants/app_constants.dart';

/// 合法分母清單（與 metronome.dart 的 _kDenominatorValues 相同）
const kDenominatorValues = [1, 2, 4, 8, 16, 32];

/// 模擬 _adjustBpm 的 clamp 邏輯
int adjustBpm(int current, int delta) {
  return (current + delta).clamp(
    AppConstants.metronomeMinBpm,
    AppConstants.metronomeMaxBpm,
  );
}

/// 模擬 BPM dialog 的 applyValue 邏輯
int? applyBpmValue(String raw, int currentBpm) {
  if (raw.isEmpty) return null; // 保留目前值
  final parsed = int.tryParse(raw);
  if (parsed == null) return null;
  return parsed.clamp(
    AppConstants.metronomeMinBpm,
    AppConstants.metronomeMaxBpm,
  );
}

/// 計算每拍的間隔毫秒（對應 _scheduleNextBeat 的公式）
double beatIntervalMs(int bpm, int denominator) {
  return (60000.0 / bpm) * (4.0 / denominator);
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // BC-M2: BPM 範圍 clamp
  // ─────────────────────────────────────────────────────────────────────────

  group('BPM 邊界 clamp (BC-M2)', () {
    test('BPM 預設值 = 120', () {
      expect(AppConstants.metronomeDefaultBpm, equals(120));
    });

    test('BPM 下限 = 20', () {
      expect(AppConstants.metronomeMinBpm, equals(20));
    });

    test('BPM 上限 = 320', () {
      expect(AppConstants.metronomeMaxBpm, equals(320));
    });

    test('BPM=120 +1 = 121', () {
      expect(adjustBpm(120, 1), equals(121));
    });

    test('BPM=320 +1 → clamp 到 320（上限）', () {
      expect(adjustBpm(320, 1), equals(320));
    });

    test('BPM=20 -1 → clamp 到 20（下限）', () {
      expect(adjustBpm(20, -1), equals(20));
    });

    test('BPM=1 -100 → clamp 到 20（下限）', () {
      // 即使從極端值開始也不超出範圍
      expect(adjustBpm(1, -100), equals(20));
    });

    test('BPM=9999 +0 → clamp 到 320（上限）', () {
      expect(adjustBpm(9999, 0), equals(320));
    });
  });

  group('BPM Dialog applyValue (BC-M2)', () {
    test('空字串 → null（保留目前值）', () {
      expect(applyBpmValue('', 120), isNull);
    });

    test('非數字字串 "abc" → null（不 throw）', () {
      expect(() => applyBpmValue('abc', 120), returnsNormally);
      expect(applyBpmValue('abc', 120), isNull);
    });

    test('負數字串 "-1" → tryParse 回傳 -1，clamp 後 = 20', () {
      // int.tryParse("-1") 合法，但 clamp 會限制到下限
      expect(applyBpmValue('-1', 120), equals(20));
    });

    test('"20" → 20（剛好在下限）', () {
      expect(applyBpmValue('20', 120), equals(20));
    });

    test('"320" → 320（剛好在上限）', () {
      expect(applyBpmValue('320', 120), equals(320));
    });

    test('"500" → clamp 到 320', () {
      expect(applyBpmValue('500', 120), equals(320));
    });

    test('"0" → clamp 到 20', () {
      expect(applyBpmValue('0', 120), equals(20));
    });

    test('"  " 空白字串 → int.tryParse 失敗 → null', () {
      // FilteringTextInputFormatter.digitsOnly 理應阻擋空白，但 applyValue 仍需健壯
      expect(applyBpmValue('  ', 120), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BC-M3: 分母合法值
  // ─────────────────────────────────────────────────────────────────────────

  group('分母合法值限制 (BC-M3)', () {
    test('合法分母清單 = [1,2,4,8,16,32]', () {
      expect(kDenominatorValues, equals([1, 2, 4, 8, 16, 32]));
    });

    test('3 不在合法分母清單中', () {
      expect(kDenominatorValues.contains(3), isFalse);
    });

    test('5 不在合法分母清單中', () {
      expect(kDenominatorValues.contains(5), isFalse);
    });

    test('7 不在合法分母清單中', () {
      expect(kDenominatorValues.contains(7), isFalse);
    });

    for (final d in [1, 2, 4, 8, 16, 32]) {
      test('$d 在合法分母清單中', () {
        expect(kDenominatorValues.contains(d), isTrue);
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BC-M5: beat interval 計算
  // ─────────────────────────────────────────────────────────────────────────

  group('Beat interval 計算 (BC-M5)', () {
    test('BPM=120, 4/4 → 500 ms/beat', () {
      expect(beatIntervalMs(120, 4), closeTo(500.0, 0.01));
    });

    test('BPM=60, 4/4 → 1000 ms/beat', () {
      expect(beatIntervalMs(60, 4), closeTo(1000.0, 0.01));
    });

    test('BPM=20（最小）, 4/4 → 3000 ms/beat', () {
      expect(beatIntervalMs(20, 4), closeTo(3000.0, 0.01));
    });

    test('BPM=320（最大）, 4/4 → 187.5 ms/beat', () {
      expect(beatIntervalMs(320, 4), closeTo(187.5, 0.01));
    });

    test('BPM=120, 8/8（分母=8）→ 250 ms（拍長是 4/4 的一半）', () {
      expect(beatIntervalMs(120, 8), closeTo(250.0, 0.01));
    });

    test('BPM=120, 6/8 pattern（分母=8）→ 每拍 250 ms', () {
      expect(beatIntervalMs(120, 8), closeTo(250.0, 0.01));
    });

    test('intervalMs 恆正（任何合法 BPM + 分母）', () {
      for (final bpm in [20, 60, 120, 200, 320]) {
        for (final denom in kDenominatorValues) {
          expect(beatIntervalMs(bpm, denom), greaterThan(0),
              reason: 'BPM=$bpm, denom=$denom');
        }
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BC-M7: _onBeat 拍數計數邏輯
  // ─────────────────────────────────────────────────────────────────────────

  group('_onBeat beat 計數循環 (BC-M7)', () {
    test('4/4：拍數 0→1→2→3→0（循環）', () {
      final beats = <int>[];
      int beat = -1; // 初始值
      for (int i = 0; i < 8; i++) {
        beat = (beat + 1) % 4;
        beats.add(beat);
      }
      expect(beats, equals([0, 1, 2, 3, 0, 1, 2, 3]));
    });

    test('3/4：拍數循環 3 次', () {
      final beats = <int>[];
      int beat = -1;
      for (int i = 0; i < 6; i++) {
        beat = (beat + 1) % 3;
        beats.add(beat);
      }
      expect(beats, equals([0, 1, 2, 0, 1, 2]));
    });

    test('6/8：分子=6，6 拍一循環', () {
      final beats = <int>[];
      int beat = -1;
      for (int i = 0; i < 12; i++) {
        beat = (beat + 1) % 6;
        beats.add(beat);
      }
      expect(beats.sublist(0, 6), equals([0, 1, 2, 3, 4, 5]));
      expect(beats[6], equals(0), reason: '第 7 拍應回到 0');
    });

    test('isNewMeasure：beat=0 且 current != -1 時為新小節', () {
      // 初始 _currentBeat = -1，第一拍後 nextBeat=0，但 isNewMeasure=false
      int currentBeat = -1;
      int next = (currentBeat + 1) % 4;
      bool isNewMeasure = next == 0 && currentBeat != -1;
      expect(isNewMeasure, isFalse, reason: '第一拍 (-1→0) 不視為新小節');

      // 第4拍後 next=0，currentBeat=3 → isNewMeasure=true
      currentBeat = 3;
      next = (currentBeat + 1) % 4;
      isNewMeasure = next == 0 && currentBeat != -1;
      expect(isNewMeasure, isTrue, reason: '小節最後一拍後應觸發 isNewMeasure');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BC-M6: Section 切換循環
  // ─────────────────────────────────────────────────────────────────────────

  group('Section 切換循環 (BC-M6)', () {
    test('兩個段落：0→1→0 循環', () {
      final totalSections = 2;
      int sectionIndex = 0;

      sectionIndex = (sectionIndex + 1) % totalSections;
      expect(sectionIndex, equals(1));

      sectionIndex = (sectionIndex + 1) % totalSections;
      expect(sectionIndex, equals(0));
    });

    test('三個段落循環', () {
      final totalSections = 3;
      int sectionIndex = 2; // 最後一個
      sectionIndex = (sectionIndex + 1) % totalSections;
      expect(sectionIndex, equals(0));
    });

    test('measure 計數：未超過 section.measures → 只遞增', () {
      int currentMeasure = 0;
      final sectionMeasures = 4;

      currentMeasure++;
      expect(currentMeasure < sectionMeasures, isTrue);

      currentMeasure = sectionMeasures - 1;
      // 下一次觸發後超過 measures，應切換段落
      bool shouldSwitch = (currentMeasure + 1) >= sectionMeasures;
      expect(shouldSwitch, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BC-M1: longPress timer 應可停止
  // ─────────────────────────────────────────────────────────────────────────

  group('長按 Timer 控制 (BC-M1)', () {
    test('onLongPressCancel 停止後 BPM 不再變化', () async {
      // 模擬長按邏輯
      int bpm = 120;
      bool timerRunning = false;
      void startLongPress() {
        timerRunning = true;
      }

      void stopLongPress() {
        timerRunning = false;
      }

      startLongPress();
      // 模擬幾次 tick
      for (int i = 0; i < 5; i++) {
        if (timerRunning) {
          bpm = (bpm + 1).clamp(20, 320);
        }
      }
      expect(bpm, equals(125));

      // 模擬 onLongPressCancel（手指滑出）
      stopLongPress();

      final bpmBeforeCancel = bpm;
      // 再次嘗試 tick，但 timerRunning=false 應阻止
      for (int i = 0; i < 5; i++) {
        if (timerRunning) {
          bpm = (bpm + 1).clamp(20, 320);
        }
      }
      expect(bpm, equals(bpmBeforeCancel), reason: 'cancel 後 BPM 不應再變化');
    });
  });
}
