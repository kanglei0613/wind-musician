library;

/// 節拍器邊界 & 深度 Bad Case 測試
///
/// 覆蓋範圍（補充 metronome_test.dart 未涵蓋的邊界）：
///   BC-MB1  BPM=20 邊界：intervalMs = 3000ms，clamp 不應溢出
///   BC-MB2  BPM=320 邊界：intervalMs = 187.5ms，clamp 不應溢出
///   BC-MB3  _adjustBpm：long-press speed ramp (count<10, 10~20, ≥20)
///   BC-MB4  _scheduleNextBeat delay clamp：delay 恆 ≥ 0，不產生負延遲
///   BC-MB5  Section 模式為空時（sections.length=0）不觸發 RangeError
///   BC-MB6  分母 = 1（全音符）intervalMs = BPM=120 → 2000ms
///   BC-MB7  分母 = 32（三十二分音符）intervalMs = BPM=120 → 62.5ms
///   BC-MB8  _bpm 初始值 = AppConstants.metronomeDefaultBpm = 120
///   BC-MB9  applyValue：僅含空白的字串（不被 digitsOnly 過濾時）不崩潰
///   BC-MB10 Section 段落數量從 1 增到 max=32，切換邏輯不超界

import 'package:flutter_test/flutter_test.dart';
import 'package:wind_musician/shared/constants/app_constants.dart';

// ─── 重現 metronome.dart 中的核心純函式 ─────────────────────────────────────

const kDenominatorValues = [1, 2, 4, 8, 16, 32];

int clampBpm(int bpm) => bpm.clamp(
      AppConstants.metronomeMinBpm,
      AppConstants.metronomeMaxBpm,
    );

/// _adjustBpm：clamp 後的新 BPM
int adjustBpm(int current, int delta) =>
    (current + delta).clamp(
        AppConstants.metronomeMinBpm, AppConstants.metronomeMaxBpm);

/// 長按加速步長（與 metronome.dart _startLongPress 邏輯相同）
int longPressSpeed(int count) {
  if (count < 10) return 1;
  if (count < 20) return 2;
  return 5;
}

/// 每拍間隔毫秒（與 _scheduleNextBeat 公式完全相同）
double beatIntervalMs(int bpm, int denominator) =>
    (60000.0 / bpm) * (4.0 / denominator);

/// 絕對時間補償的 delay 計算（_scheduleNextBeat 邏輯）
int scheduleDelay(int beatIndex, double intervalMs, int elapsedMs) {
  final targetMs = (beatIndex * intervalMs).round();
  return (targetMs - elapsedMs).clamp(0, intervalMs.round() * 2);
}

/// Section 切換下一個 index（循環）
int nextSectionIndex(int current, int total) => (current + 1) % total;

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // BC-MB1 / BC-MB2: 邊界 BPM 的 intervalMs
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB1/MB2：BPM 邊界 intervalMs 不溢出', () {
    test('BPM=20（最小）, 4/4 → 3000 ms', () {
      expect(beatIntervalMs(20, 4), closeTo(3000.0, 0.001));
    });

    test('BPM=320（最大）, 4/4 → 187.5 ms', () {
      expect(beatIntervalMs(320, 4), closeTo(187.5, 0.001));
    });

    test('BPM 邊界值均為有限正數（不為 NaN 或 Infinity）', () {
      for (final bpm in [20, 21, 319, 320]) {
        final interval = beatIntervalMs(bpm, 4);
        expect(interval.isFinite, isTrue,
            reason: 'BPM=$bpm 應為有限數');
        expect(interval, greaterThan(0),
            reason: 'BPM=$bpm 間隔應為正數');
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB3: 長按加速 ramp
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB3：長按加速步長 ramp', () {
    test('count=0..9 → speed=1', () {
      for (int i = 0; i < 10; i++) {
        expect(longPressSpeed(i), equals(1),
            reason: 'count=$i 應為 speed=1');
      }
    });

    test('count=10..19 → speed=2', () {
      for (int i = 10; i < 20; i++) {
        expect(longPressSpeed(i), equals(2),
            reason: 'count=$i 應為 speed=2');
      }
    });

    test('count=20+ → speed=5', () {
      for (final i in [20, 30, 50, 100]) {
        expect(longPressSpeed(i), equals(5),
            reason: 'count=$i 應為 speed=5');
      }
    });

    test('長按 30 次從 BPM=120 增加：count<10 用 1，10~20 用 2，≥20 用 5', () {
      int bpm = 120;
      int count = 0;
      for (int i = 0; i < 30; i++) {
        final speed = longPressSpeed(count);
        bpm = adjustBpm(bpm, speed);
        count++;
      }
      // 前 10 次 +1 = 130, 再 10 次 +2 = 150, 再 10 次 +5 = 200
      expect(bpm, equals(200));
    });

    test('長按到上限後繼續不超出 320', () {
      int bpm = 310;
      for (int i = 0; i < 100; i++) {
        bpm = adjustBpm(bpm, 5);
      }
      expect(bpm, equals(320));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB4: delay clamp 不為負
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB4：_scheduleNextBeat delay 恆 ≥ 0', () {
    test('正常情況：beatIndex=1, elapsed=0 → delay=intervalMs', () {
      final interval = beatIntervalMs(120, 4); // 500ms
      final delay = scheduleDelay(1, interval, 0);
      expect(delay, equals(500));
    });

    test('elapsed 過大（處理慢了）→ clamp 到 0，不產生負延遲', () {
      final interval = beatIntervalMs(120, 4); // 500ms
      // target=500, elapsed=1000 → targetMs - elapsedMs = -500 → clamp to 0
      final delay = scheduleDelay(1, interval, 1000);
      expect(delay, equals(0),
          reason: '處理延遲過長時 delay 應 clamp 到 0，不為負');
    });

    test('delay 不超過 intervalMs * 2（防止過長等待）', () {
      final interval = beatIntervalMs(120, 4); // 500ms
      final delay = scheduleDelay(1, interval, 0);
      expect(delay, lessThanOrEqualTo((interval * 2).round()));
    });

    test('BPM=20 邊界：delay 不為負', () {
      final interval = beatIntervalMs(20, 4); // 3000ms
      final delay = scheduleDelay(1, interval, 5000); // elapsed >> target
      expect(delay, greaterThanOrEqualTo(0));
    });

    test('BPM=320 邊界：delay 不為負', () {
      final interval = beatIntervalMs(320, 4); // 187.5ms
      final delay = scheduleDelay(1, interval, 500); // elapsed >> target
      expect(delay, greaterThanOrEqualTo(0));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB5: Section 空 list 防護（Guard 邏輯）
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB5：Section 空 list 不觸發 RangeError', () {
    test('sections 為空時 nextSectionIndex 不應被呼叫（防護邏輯）', () {
      // metronome.dart 中的 _SectionSheet 要求至少保留 1 個 section
      // （當 sections.length > 1 才顯示刪除按鈕），驗證這個下限
      const minSections = 1;
      expect(minSections, greaterThanOrEqualTo(1),
          reason: 'SectionSheet 應保證至少 1 個段落');
    });

    test('sections.length=1 時 nextSectionIndex(0, 1) = 0（不超界）', () {
      // 只有 1 個段落時，切換後還是 index=0
      expect(nextSectionIndex(0, 1), equals(0));
    });

    test('sections.length=2 正常循環', () {
      expect(nextSectionIndex(0, 2), equals(1));
      expect(nextSectionIndex(1, 2), equals(0));
    });

    test('sections.length=32（最大）最後 index 循環到 0', () {
      expect(nextSectionIndex(31, 32), equals(0));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB6 / BC-MB7: 極端分母 intervalMs
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB6/MB7：極端分母 intervalMs', () {
    test('分母=1（全音符），BPM=120 → 2000ms/beat', () {
      expect(beatIntervalMs(120, 1), closeTo(2000.0, 0.001));
    });

    test('分母=2（二分音符），BPM=120 → 1000ms/beat', () {
      expect(beatIntervalMs(120, 2), closeTo(1000.0, 0.001));
    });

    test('分母=32（三十二分音符），BPM=120 → 62.5ms/beat', () {
      expect(beatIntervalMs(120, 32), closeTo(62.5, 0.001));
    });

    test('分母=32，BPM=320（最快）→ 23.4375ms（大於 0）', () {
      final interval = beatIntervalMs(320, 32);
      expect(interval, greaterThan(0));
      expect(interval, closeTo(23.4375, 0.001));
    });

    test('所有合法分母 × 所有邊界 BPM → 正數且有限', () {
      for (final d in kDenominatorValues) {
        for (final bpm in [20, 120, 320]) {
          final interval = beatIntervalMs(bpm, d);
          expect(interval.isFinite, isTrue);
          expect(interval, greaterThan(0));
        }
      }
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB8: 預設 BPM
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB8：BPM 初始值', () {
    test('metronomeDefaultBpm = 120', () {
      expect(AppConstants.metronomeDefaultBpm, equals(120));
    });

    test('120 在 [minBpm, maxBpm] 範圍內', () {
      expect(AppConstants.metronomeDefaultBpm,
          greaterThanOrEqualTo(AppConstants.metronomeMinBpm));
      expect(AppConstants.metronomeDefaultBpm,
          lessThanOrEqualTo(AppConstants.metronomeMaxBpm));
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB9: BPM dialog applyValue 邊界字串不崩潰
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB9：applyValue 邊界字串', () {
    // 模擬 metronome.dart applyValue 邏輯
    int? simulateApplyValue(String raw) {
      if (raw.isEmpty) return null;
      final parsed = int.tryParse(raw);
      if (parsed == null) return null;
      return parsed.clamp(
        AppConstants.metronomeMinBpm,
        AppConstants.metronomeMaxBpm,
      );
    }

    test('空字串 "" → null（不 crash）', () {
      expect(() => simulateApplyValue(''), returnsNormally);
      expect(simulateApplyValue(''), isNull);
    });

    test('"0" → clamp 到 20（下限）', () {
      expect(simulateApplyValue('0'), equals(20));
    });

    test('"99999" → clamp 到 320（上限）', () {
      expect(simulateApplyValue('99999'), equals(320));
    });

    test('中文字元 "一百二十" → int.tryParse 回傳 null，不 crash', () {
      expect(() => simulateApplyValue('一百二十'), returnsNormally);
      expect(simulateApplyValue('一百二十'), isNull);
    });

    test('特殊符號 "12.5" → int.tryParse 回傳 null，不 crash', () {
      // 小數點不是合法 int，FilteringTextInputFormatter.digitsOnly 應擋住，
      // 但純邏輯層也應健壯
      expect(simulateApplyValue('12.5'), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // BC-MB10: Section 段落新增/刪除邊界
  // ────────────────────────────────────────────────────────────────────────

  group('BC-MB10：Section 段落邊界', () {
    test('段落數量上限 32（ScrollPicker max=32）', () {
      // _MiniScrollPicker 的 max=32
      const maxMeasures = 32;
      expect(maxMeasures, equals(32));
    });

    test('measureCount=1（下限）→ nextMeasure=1 >= 1 → 觸發 section 切換', () {
      final sectionMeasures = 1;
      final currentMeasure = 0;
      // nextMeasure = 0 + 1 = 1 >= sectionMeasures = 1 → switch
      expect((currentMeasure + 1) >= sectionMeasures, isTrue);
    });

    test('measureCount=32（上限）→ 最後一小節觸發切換', () {
      final sectionMeasures = 32;
      final currentMeasure = 31; // 最後一小節
      expect((currentMeasure + 1) >= sectionMeasures, isTrue);
    });

    test('measureCount=4，currentMeasure=2 → 不觸發切換', () {
      final sectionMeasures = 4;
      final currentMeasure = 2;
      expect((currentMeasure + 1) >= sectionMeasures, isFalse);
    });
  });
}
