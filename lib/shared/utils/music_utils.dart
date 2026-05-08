library;

import 'dart:math' as math;

class Instrument {
  final String name;
  final String nameEn;
  final String localizationKey; // ← 新增，對應 arb 的 key
  final int transposeSteps;
  final String key;

  const Instrument({
    required this.name,
    required this.nameEn,
    required this.localizationKey,
    required this.transposeSteps,
    required this.key,
  });
}

class Instruments {
  Instruments._();

  static const concertPitch = Instrument(
    name: 'Concert Pitch', nameEn: 'Concert Pitch',
    localizationKey: 'instrumentConcertPitch',
    transposeSteps: 0, key: 'C',
  );
  static const flute = Instrument(
    name: '長笛', nameEn: 'Flute',
    localizationKey: 'instrumentFlute',
    transposeSteps: 0, key: 'C',
  );
  static const oboe = Instrument(
    name: '雙簧管', nameEn: 'Oboe',
    localizationKey: 'instrumentOboe',
    transposeSteps: 0, key: 'C',
  );
  static const bassoon = Instrument(
    name: '低音管', nameEn: 'Bassoon',
    localizationKey: 'instrumentBassoon',
    transposeSteps: 0, key: 'C',
  );
  static const trombone = Instrument(
    name: '長號', nameEn: 'Trombone',
    localizationKey: 'instrumentTrombone',
    transposeSteps: 0, key: 'C',
  );
  static const tuba = Instrument(
    name: '大號', nameEn: 'Tuba',
    localizationKey: 'instrumentTuba',
    transposeSteps: 0, key: 'C',
  );
  static const trumpet = Instrument(
    name: '小號', nameEn: 'Trumpet',
    localizationKey: 'instrumentTrumpet',
    transposeSteps: 2, key: 'Bb',
  );
  static const clarinet = Instrument(
    name: '單簧管', nameEn: 'Clarinet',
    localizationKey: 'instrumentClarinet',
    transposeSteps: 2, key: 'Bb',
  );
  static const tenorSax = Instrument(
    name: '次中音薩克斯風', nameEn: 'Tenor Saxophone',
    localizationKey: 'instrumentTenorSax',
    transposeSteps: 2, key: 'Bb',
  );
  static const euphonium = Instrument(
    name: '上低音號', nameEn: 'Euphonium',
    localizationKey: 'instrumentEuphonium',
    transposeSteps: 2, key: 'Bb',
  );
  static const bassClarinet = Instrument(
    name: '低音單簧管', nameEn: 'Bass Clarinet',
    localizationKey: 'instrumentBassClarinet',
    transposeSteps: 2, key: 'Bb',
  );
  static const altoSax = Instrument(
    name: '中音薩克斯風', nameEn: 'Alto Saxophone',
    localizationKey: 'instrumentAltoSax',
    transposeSteps: 9, key: 'Eb',
  );
  static const baritoneSax = Instrument(
    name: '上低音薩克斯風', nameEn: 'Baritone Saxophone',
    localizationKey: 'instrumentBaritoneSax',
    transposeSteps: 9, key: 'Eb',
  );
  static const ebClarinet = Instrument(
    name: 'Eb 單簧管', nameEn: 'Eb Clarinet',
    localizationKey: 'instrumentEbClarinet',
    transposeSteps: 9, key: 'Eb',
  );
  static const frenchHorn = Instrument(
    name: '法國號', nameEn: 'French Horn',
    localizationKey: 'instrumentFrenchHorn',
    transposeSteps: 7, key: 'F',
  );
  static const englishHorn = Instrument(
    name: '英國號', nameEn: 'English Horn',
    localizationKey: 'instrumentEnglishHorn',
    transposeSteps: 7, key: 'F',
  );

  static const all = [
    concertPitch, flute, oboe, bassoon, trombone, tuba,
    trumpet, clarinet, tenorSax, euphonium, bassClarinet,
    altoSax, baritoneSax, ebClarinet,
    frenchHorn, englishHorn,
  ];

  static Map<String, List<Instrument>> get grouped => {
    'Concert Pitch': [concertPitch, flute, oboe, bassoon, trombone, tuba],
    'Bb': [trumpet, clarinet, tenorSax, euphonium, bassClarinet],
    'Eb': [altoSax, baritoneSax, ebClarinet],
    'F': [frenchHorn, englishHorn],
  };
}

class MusicUtils {
  MusicUtils._();

  static const _noteNames = [
    'C', 'Db', 'D', 'Eb', 'E', 'F',
    'Gb', 'G', 'Ab', 'A', 'Bb', 'B',
  ];

  static PitchInfo? frequencyToPitch(
    double frequency, {
    double a4Reference = 440.0,
    int transposeSteps = 0,
  }) {
    if (frequency <= 0 || frequency < 25 || frequency > 5000) return null;

    final semitones = 12 * (math.log(frequency / a4Reference) / math.log(2));
    final nearestSemitone = semitones.round();
    final centsOff = (semitones - nearestSemitone) * 100;

    final midiNote = 69 + nearestSemitone;
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

class PitchInfo {
  final double frequency;
  final String noteName;
  final int octave;
  final double centsOff;
  final int midiNote;
  final int transposedMidiNote;

  const PitchInfo({
    required this.frequency,
    required this.noteName,
    required this.octave,
    required this.centsOff,
    required this.midiNote,
    required this.transposedMidiNote,
  });

  String get noteOctave => '$noteName$octave';
  bool get isInTune => centsOff.abs() <= 10;
  bool get isSharp => centsOff > 10;
  bool get isFlat => centsOff < -10;

  String get centsDisplay {
    final rounded = centsOff.round();
    return rounded >= 0 ? '+$rounded' : '$rounded';
  }
}
