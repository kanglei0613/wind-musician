// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '관악기 수첩';

  @override
  String get navTuner => '튜너';

  @override
  String get navRecorder => '녹음';

  @override
  String get navAnalysis => '분석';

  @override
  String get navSchedule => '일정';

  @override
  String get tunerTitle => '튜너';

  @override
  String get tunerInTune => '정확';

  @override
  String get tunerSharp => '높음';

  @override
  String get tunerFlat => '낮음';

  @override
  String get recorderTitle => '녹음';

  @override
  String get recorderStart => '녹음 시작';

  @override
  String get recorderStop => '정지';

  @override
  String get recorderNoRecordings => '녹음이 없습니다';

  @override
  String get analysisTitle => 'AI 분석';

  @override
  String get analysisStart => '분석 시작';

  @override
  String get analysisLoading => '분석 중...';

  @override
  String get analysisMusicianLabel => '음악가 스타일 선택';

  @override
  String get scheduleTitle => '일정';

  @override
  String get scheduleAdd => '연습 추가';

  @override
  String get scheduleNoEvents => '일정이 없습니다';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsTunerReference => '튜너 기준 음높이';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '한국어';

  @override
  String get errorGeneral => '오류가 발생했습니다. 다시 시도해 주세요';

  @override
  String get errorNetwork => '네트워크 연결에 실패했습니다';
}
