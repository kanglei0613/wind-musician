// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '管樂手帳';

  @override
  String get navTuner => '調音器';

  @override
  String get navRecorder => '錄音';

  @override
  String get navAnalysis => '分析';

  @override
  String get navSchedule => '行程';

  @override
  String get tunerTitle => '調音器';

  @override
  String get tunerInTune => '準確';

  @override
  String get tunerSharp => '偏高';

  @override
  String get tunerFlat => '偏低';

  @override
  String get recorderTitle => '錄音';

  @override
  String get recorderStart => '開始錄音';

  @override
  String get recorderStop => '停止';

  @override
  String get recorderNoRecordings => '還沒有錄音紀錄';

  @override
  String get analysisTitle => 'AI 分析';

  @override
  String get analysisStart => '開始分析';

  @override
  String get analysisLoading => '分析中...';

  @override
  String get analysisMusicianLabel => '選擇音樂家風格';

  @override
  String get scheduleTitle => '行程';

  @override
  String get scheduleAdd => '新增練習';

  @override
  String get scheduleNoEvents => '還沒有行程紀錄';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsTunerReference => '調音基準音高';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '한국어';

  @override
  String get errorGeneral => '發生錯誤，請稍後再試';

  @override
  String get errorNetwork => '網路連線失敗';
}
