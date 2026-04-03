// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Wind Musician';

  @override
  String get navTuner => 'Tuner';

  @override
  String get navRecorder => 'Recorder';

  @override
  String get navAnalysis => 'Analysis';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get tunerTitle => 'Tuner';

  @override
  String get tunerInTune => 'In Tune';

  @override
  String get tunerSharp => 'Sharp';

  @override
  String get tunerFlat => 'Flat';

  @override
  String get recorderTitle => 'Recorder';

  @override
  String get recorderStart => 'Start Recording';

  @override
  String get recorderStop => 'Stop';

  @override
  String get recorderNoRecordings => 'No recordings yet';

  @override
  String get analysisTitle => 'AI Analysis';

  @override
  String get analysisStart => 'Start Analysis';

  @override
  String get analysisLoading => 'Analyzing...';

  @override
  String get analysisMusicianLabel => 'Select Musician Style';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleAdd => 'Add Practice';

  @override
  String get scheduleNoEvents => 'No schedule yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTunerReference => 'Tuner Reference Pitch';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '한국어';

  @override
  String get errorGeneral => 'Something went wrong, please try again';

  @override
  String get errorNetwork => 'Network connection failed';
}
