// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '管楽器手帳';

  @override
  String get navTuner => 'チューナー';

  @override
  String get navRecorder => '録音';

  @override
  String get navAnalysis => '分析';

  @override
  String get navSchedule => 'スケジュール';

  @override
  String get tunerTitle => 'チューナー';

  @override
  String get tunerInTune => '正確';

  @override
  String get tunerSharp => '高い';

  @override
  String get tunerFlat => '低い';

  @override
  String get recorderTitle => '録音';

  @override
  String get recorderStart => '録音開始';

  @override
  String get recorderStop => '停止';

  @override
  String get recorderNoRecordings => '録音がまだありません';

  @override
  String get analysisTitle => 'AI分析';

  @override
  String get analysisStart => '分析開始';

  @override
  String get analysisLoading => '分析中...';

  @override
  String get analysisMusicianLabel => '音楽家スタイルを選択';

  @override
  String get scheduleTitle => 'スケジュール';

  @override
  String get scheduleAdd => '練習を追加';

  @override
  String get scheduleNoEvents => 'スケジュールがまだありません';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsTunerReference => 'チューナー基準音高';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '한국어';

  @override
  String get errorGeneral => 'エラーが発生しました。後でもう一度お試しください';

  @override
  String get errorNetwork => 'ネットワーク接続に失敗しました';
}
