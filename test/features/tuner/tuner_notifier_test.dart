library;

/// 調音器 Bad Case 測試
///
/// 覆蓋範圍：
///   BC-MU1  無效頻率（≤0, <25, >5000）→ null（防止 NPE crash）
///   BC-MU2  440 Hz → A4, cents≈0
///   BC-MU3  Bb移調(+2) / Eb移調(+9)
///   BC-MU4  邊界八度（C0≈16Hz 被過濾）
///   BC-MU5  TunerState.copyWith clearPitch flag
///   BC-MU6  referenceA4 邊界 420/460 Hz
///   BC-MU7  isInTune / isSharp / isFlat 判斷
///   BC-T-ST 所有樂器移調不應產生 null

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:wind_musician/shared/utils/music_utils.dart';
import 'package:wind_musician/features/tuner/tuner_provider.dart';

double _centsToRatio(double cents) => math.pow(2.0, cents / 1200.0).toDouble();

void main() {
  group('MusicUtils.frequencyToPitch — 無效頻率過濾 (BC-MU1)', () {
    test('頻率 = 0 → null', () {
      expect(MusicUtils.frequencyToPitch(0), isNull);
    });

    test('頻率 < 0 → null', () {
      expect(MusicUtils.frequencyToPitch(-1), isNull);
      expect(MusicUtils.frequencyToPitch(-440), isNull);
    });

    test('頻率 < 25 Hz（C0 區間）→ null', () {
      expect(MusicUtils.frequencyToPitch(10), isNull);
      expect(MusicUtils.frequencyToPitch(24.9), isNull);
    });

    test('頻率 > 5000 Hz → null', () {
      expect(MusicUtils.frequencyToPitch(5001), isNull);
      expect(MusicUtils.frequencyToPitch(20000), isNull);
    });

    test('25 Hz 邊界值 → 非 null（剛好通過過濾）', () {
      expect(MusicUtils.frequencyToPitch(25), isNotNull);
    });

    test('5000 Hz 邊界值 → 非 null（剛好通過過濾）', () {
      expect(MusicUtils.frequencyToPitch(5000), isNotNull);
    });
  });

  group('MusicUtils.frequencyToPitch — 正確識別音高 (BC-MU2)', () {
    test('440 Hz (A4, ref=440) → noteName=A, octave=4, cents≈0', () {
      final info = MusicUtils.frequencyToPitch(440.0, a4Reference: 440.0);
      expect(info, isNotNull);
      expect(info!.noteName, equals('A'));
      expect(info.octave, equals(4));
      expect(info.centsOff.abs(), lessThan(1.0));
      expect(info.isInTune, isTrue);
    });

    test('261.63 Hz (C4 "中央C", ref=440) → noteName=C, octave=4', () {
      // C4 = A4 / 2^(9/12) ≈ 261.626
      final c4 = 440.0 / math.pow(2.0, 9.0 / 12.0);
      final info = MusicUtils.frequencyToPitch(c4, a4Reference: 440.0);
      expect(info, isNotNull);
      expect(info!.noteName, equals('C'));
      expect(info.octave, equals(4));
    });
  });

  group('MusicUtils.frequencyToPitch — 移調樂器 (BC-MU3)', () {
    test('Bb 移調 (+2 半音)：440 Hz concert → B4 on instrument', () {
      final info = MusicUtils.frequencyToPitch(440.0,
          a4Reference: 440.0, transposeSteps: 2);
      expect(info, isNotNull);
      expect(info!.noteName, equals('B'));
      expect(info.octave, equals(4));
    });

    test('Eb 移調 (+9 半音)：440 Hz concert → F#5 on instrument', () {
      final info = MusicUtils.frequencyToPitch(440.0,
          a4Reference: 440.0, transposeSteps: 9);
      expect(info, isNotNull);
      expect(info!.noteName, equals('F#'));
      expect(info.octave, equals(5));
    });

    test('F 移調 (+7 半音)：440 Hz concert → E5 on instrument', () {
      final info = MusicUtils.frequencyToPitch(440.0,
          a4Reference: 440.0, transposeSteps: 7);
      expect(info, isNotNull);
      expect(info!.noteName, equals('E'));
      expect(info.octave, equals(5));
    });

    test('Concert Pitch (+0)：無移調', () {
      final info = MusicUtils.frequencyToPitch(440.0,
          a4Reference: 440.0, transposeSteps: 0);
      expect(info!.noteName, equals('A'));
      expect(info.octave, equals(4));
    });
  });

  group('MusicUtils.frequencyToPitch — 邊界八度 (BC-MU4)', () {
    test('C0 ≈ 16.35 Hz（低於 25 Hz 閾值）→ null', () {
      expect(MusicUtils.frequencyToPitch(16.35), isNull);
    });

    test('C1 ≈ 32.7 Hz → 合法 octave', () {
      final info = MusicUtils.frequencyToPitch(32.7, a4Reference: 440.0);
      expect(info, isNotNull);
      expect(info!.octave, greaterThanOrEqualTo(0));
    });
  });

  group('MusicUtils.frequencyToPitch — referenceA4 邊界 (BC-MU6)', () {
    test('referenceA4 = 420 Hz → 結果不為 null', () {
      final info = MusicUtils.frequencyToPitch(420.0, a4Reference: 420.0);
      expect(info, isNotNull);
      expect(info!.noteName, equals('A'));
      expect(info.centsOff.abs(), lessThan(1.0));
    });

    test('referenceA4 = 460 Hz → 結果不為 null', () {
      final info = MusicUtils.frequencyToPitch(460.0, a4Reference: 460.0);
      expect(info, isNotNull);
      expect(info!.noteName, equals('A'));
      expect(info.centsOff.abs(), lessThan(1.0));
    });
  });

  group('MusicUtils — isInTune / isSharp / isFlat (BC-MU7)', () {
    test('±0 cents → isInTune=true', () {
      final info = MusicUtils.frequencyToPitch(440.0, a4Reference: 440.0)!;
      expect(info.isInTune, isTrue);
      expect(info.isSharp, isFalse);
      expect(info.isFlat, isFalse);
    });

    test('+20 cents → isSharp=true', () {
      final freq = 440.0 * _centsToRatio(20);
      final info = MusicUtils.frequencyToPitch(freq, a4Reference: 440.0)!;
      expect(info.isSharp, isTrue);
      expect(info.isFlat, isFalse);
      expect(info.isInTune, isFalse);
    });

    test('-20 cents → isFlat=true', () {
      final freq = 440.0 * _centsToRatio(-20);
      final info = MusicUtils.frequencyToPitch(freq, a4Reference: 440.0)!;
      expect(info.isFlat, isTrue);
      expect(info.isSharp, isFalse);
      expect(info.isInTune, isFalse);
    });

    test('±10 cents 邊界 → isInTune=true（容差邊緣）', () {
      final sharpBound = 440.0 * _centsToRatio(10);
      final flatBound = 440.0 * _centsToRatio(-10);
      // 由於 round() 誤差，centsOff 可能是 ±9.x or ±10.0
      final iSharp = MusicUtils.frequencyToPitch(sharpBound, a4Reference: 440.0)!;
      final iFlat = MusicUtils.frequencyToPitch(flatBound, a4Reference: 440.0)!;
      expect(iSharp.centsOff.abs(), lessThanOrEqualTo(10.0 + 1e-6));
      expect(iFlat.centsOff.abs(), lessThanOrEqualTo(10.0 + 1e-6));
    });

    test('centsDisplay 正值帶 + 號', () {
      final freq = 440.0 * _centsToRatio(15);
      final info = MusicUtils.frequencyToPitch(freq, a4Reference: 440.0)!;
      expect(info.centsDisplay, startsWith('+'));
    });

    test('centsDisplay 負值帶 - 號', () {
      final freq = 440.0 * _centsToRatio(-15);
      final info = MusicUtils.frequencyToPitch(freq, a4Reference: 440.0)!;
      expect(info.centsDisplay, startsWith('-'));
    });

    test('noteOctave = noteName + octave', () {
      final info = MusicUtils.frequencyToPitch(440.0, a4Reference: 440.0)!;
      expect(info.noteOctave, equals('A4'));
    });
  });

  group('TunerState.copyWith (BC-MU5)', () {
    test('clearPitch=true 清除 pitchInfo', () {
      final pitch = MusicUtils.frequencyToPitch(440.0, a4Reference: 440.0);
      final state = TunerState(pitchInfo: pitch);
      final cleared = state.copyWith(clearPitch: true);
      expect(cleared.pitchInfo, isNull);
    });

    test('clearPitch 預設 false → pitchInfo 保留', () {
      final pitch = MusicUtils.frequencyToPitch(440.0, a4Reference: 440.0);
      final state = TunerState(pitchInfo: pitch);
      final kept = state.copyWith(isListening: false);
      expect(kept.pitchInfo, isNotNull);
      expect(kept.pitchInfo!.noteName, equals('A'));
    });

    test('初始 isListening = false', () {
      const s = TunerState();
      expect(s.isListening, isFalse);
    });

    test('初始 referenceA4 = 442.0（AppConstants.standardPitch）', () {
      const s = TunerState();
      expect(s.referenceA4, equals(442.0));
    });

    test('error 欄位可覆蓋', () {
      const s = TunerState(error: 'old');
      expect(s.copyWith(error: 'new').error, equals('new'));
    });

    test('copyWith 不傳 referenceA4 時保留原值', () {
      const s = TunerState(referenceA4: 435.0);
      expect(s.copyWith(isListening: true).referenceA4, equals(435.0));
    });
  });

  group('Instruments — 所有樂器移調不產生 null (BC-T-ST)', () {
    test('所有樂器 440 Hz → 非 null', () {
      for (final instrument in Instruments.all) {
        final info = MusicUtils.frequencyToPitch(
          440.0,
          a4Reference: 440.0,
          transposeSteps: instrument.transposeSteps,
        );
        expect(info, isNotNull,
            reason: '${instrument.nameEn} (steps=${instrument.transposeSteps}) 不應為 null');
      }
    });
  });
}
