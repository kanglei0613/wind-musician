library;

import 'dart:math' as math;

/// 樂器調性定義
class Instrument {
  /// 樂器名稱（顯示用）
  final String name;

  /// 樂器名稱（英文）
  final String nameEn;

  /// 移調半音數
  /// Concert Pitch = 0
  /// Bb 調 = +2（顯示音名比實際高2個半音）
  /// Eb 調 = +9
  /// F 調 = +7
  final int transposeSteps;

  /// 調性名稱（C、Bb、Eb、F）
  final String key;

  const Instrument({
    required this.name,
    required this.nameEn,
    required this.transposeSteps,
    required this.key,
  });
}

/// 所有支援的樂器清單
class Instruments {
  Instruments._();

  // ── Concert Pitch ─────────────────────────────────
  static const concertPitch = Instrument(
    name: 'Concert Pitch',
    nameEn: 'Concert Pitch',
    transposeSteps: 0,
    key: 'C',
  );

  static const flute = Instrument(
    name: '長笛',
    nameEn: 'Flute',
    transposeSteps: 0,
    key: 'C',
  );

  static const oboe = Instrument(
    name: '雙簧管',
    nameEn: 'Oboe',
    transposeSteps: 0,
    key: 'C',
  );

  static const bassoon = Instrument(
    name: '低音管',
    nameEn: 'Bassoon',
    transposeSteps: 0,
    key: 'C',
  );

  static const trombone = Instrument(
    name: '長號',
    nameEn: 'Trombone',
    transposeSteps: 0,
    key: 'C',
  );

  static const tuba = Instrument(
    name: '大號',
    nameEn: 'Tuba',
    transposeSteps: 0,
    key: 'C',
  );

  // ── Bb 調 ─────────────────────────────────────────
  static const trumpet = Instrument(
    name: '小號',
    nameEn: 'Trumpet',
    transposeSteps: 2,
    key: 'Bb',
  );

  static const clarinet = Instrument(
    name: '單簧管',
    nameEn: 'Clarinet',
    transposeSteps: 2,
    key: 'Bb',
  );

  static const tenorSax = Instrument(
    name: '次中音薩克斯風',
    nameEn: 'Tenor Saxophone',
    transposeSteps: 2,
    key: 'Bb',
  );

  static const euphonium = Instrument(
    name: '上低音號',
    nameEn: 'Euphonium',
    transposeSteps: 2,
    key: 'Bb',
  );

  static const bassClarinet = Instrument(
    name: '低音單簧管',
    nameEn: 'Bass Clarinet',
    transposeSteps: 2,
    key: 'Bb',
  );

  // ── Eb 調 ─────────────────────────────────────────
  static const altoSax = Instrument(
    name: '中音薩克斯風',
    nameEn: 'Alto Saxophone',
    transposeSteps: 9,
    key: 'Eb',
  );

  static const baritoneSax = Instrument(
    name: '上低音薩克斯風',
    nameEn: 'Baritone Saxophone',
    transposeSteps: 9,
    key: 'Eb',
  );

  static const ebClarinet = Instrument(
    name: 'Eb 單簧管',
    nameEn: 'Eb Clarinet',
    transposeSteps: 9,
    key: 'Eb',
  );

  // ── F 調 ──────────────────────────────────────────
  static const frenchHorn = Instrument(
    name: '法國號',
    nameEn: 'French Horn',
    transposeSteps: 7,
    key: 'F',
  );

  static const englishHorn = Instrument(
    name: '英國號',
    nameEn: 'English Horn',
    transposeSteps: 7,
    key: 'F',
  );

  /// 所有樂器清單（依調性分組）
  static const all = [
    concertPitch,
    flute,
    oboe,
    bassoon,
    trombone,
    tuba,
    trumpet,
    clarinet,
    tenorSax,
    euphonium,
    bassClarinet,
    altoSax,
    baritoneSax,
    ebClarinet,
    frenchHorn,
    englishHorn,
  ];

  /// 依調性分組的樂器清單
  static Map<String, List<Instrument>> get grouped => {
    'Concert Pitch': [concertPitch, flute, oboe, bassoon, trombone, tuba],
    'Bb 調': [trumpet, clarinet, tenorSax, euphonium, bassClarinet],
    'Eb 調': [altoSax, baritoneSax, ebClarinet],
    'F 調': [frenchHorn, englishHorn],
  };
}

/// 音樂工具函式
class MusicUtils {
  MusicUtils._();

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// 把頻率轉成音樂資訊
  /// [frequency] 偵測到的頻率（Hz）
  /// [a4Reference] A4 基準音高，預設 440Hz
  /// [transposeSteps] 移調半音數，Concert Pitch = 0
  static PitchInfo? frequencyToPitch(
    double frequency, {
    double a4Reference = 440.0,
    int transposeSteps = 0,
  }) {
    if (frequency <= 0 || frequency < 20 || frequency > 8000) return null;

    // 計算距離 A4 的半音數
    final semitones = 12 * (math.log(frequency / a4Reference) / math.log(2));
    final nearestSemitone = semitones.round();
    final centsOff = (semitones - nearestSemitone) * 100;

    // MIDI 音符編號（A4 = 69）
    final midiNote = 69 + nearestSemitone;

    // 加上移調半音數後計算音名
    final transposedMidi = midiNote + transposeSteps;
    final octave = (transposedMidi / 12).floor() - 1;
    final noteIndex = transposedMidi % 12;

    if (noteIndex < 0 || noteIndex >= _noteNames.length) return null;
    if (octave < 0 || octave > 9) return null;

    return PitchInfo(
      frequency: frequency,
      noteName: _noteNames[noteIndex],
      octave: octave,
      centsOff: centsOff,
      midiNote: midiNote,
      transposedMidiNote: transposedMidi,
    );
  }
}

/// 音高資訊
class PitchInfo {
  /// 原始頻率（Hz）
  final double frequency;

  /// 移調後的音名
  final String noteName;

  /// 移調後的八度
  final int octave;

  /// 音分偏差（-50 到 +50）
  final double centsOff;

  /// 原始 MIDI 音符編號（Concert Pitch）
  final int midiNote;

  /// 移調後的 MIDI 音符編號
  final int transposedMidiNote;

  const PitchInfo({
    required this.frequency,
    required this.noteName,
    required this.octave,
    required this.centsOff,
    required this.midiNote,
    required this.transposedMidiNote,
  });

  /// 音名 + 八度（例如 A4、C5）
  String get noteOctave => '$noteName$octave';

  bool get isInTune => centsOff.abs() <= 10;
  bool get isSharp => centsOff > 10;
  bool get isFlat => centsOff < -10;

  String get centsDisplay {
    final rounded = centsOff.round();
    return rounded >= 0 ? '+$rounded' : '$rounded';
  }
}
