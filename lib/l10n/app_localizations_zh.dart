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
  String get tunerInTune => '準確';

  @override
  String get tunerSharp => '偏高';

  @override
  String get tunerFlat => '偏低';

  @override
  String get tunerReference => '調音基準音高';

  @override
  String get tunerReferenceCommon => '常用設定';

  @override
  String get tunerSelectInstrument => '選擇樂器';

  @override
  String get instrumentConcertPitch => 'Concert Pitch';

  @override
  String get instrumentFlute => '長笛';

  @override
  String get instrumentOboe => '雙簧管';

  @override
  String get instrumentBassoon => '低音管';

  @override
  String get instrumentTrombone => '長號';

  @override
  String get instrumentTuba => '低音號';

  @override
  String get instrumentTrumpet => '小號';

  @override
  String get instrumentClarinet => '單簧管';

  @override
  String get instrumentTenorSax => '次中音薩克斯風';

  @override
  String get instrumentEuphonium => '上低音號';

  @override
  String get instrumentBassClarinet => '低音單簧管';

  @override
  String get instrumentAltoSax => '中音薩克斯風';

  @override
  String get instrumentBaritoneSax => '上低音薩克斯風';

  @override
  String get instrumentEbClarinet => 'Eb 單簧管';

  @override
  String get instrumentFrenchHorn => '法國號';

  @override
  String get instrumentEnglishHorn => '英國管';

  @override
  String get tunerDone => '完成';

  @override
  String get tunerCancel => '取消';

  @override
  String get metronomeInputBpm => '輸入 BPM';

  @override
  String get metronomeSection => '段落練習';

  @override
  String get metronomeSectionAdd => '新增段落';

  @override
  String get metronomeSectionEnable => '開啟段落練習模式，可設定多段不同拍號的練習循環。';

  @override
  String get metronomeSectionLabel => '段落';

  @override
  String get metronomeMeasure => '小節';

  @override
  String get terminologyTitle => '音樂術語查詢';

  @override
  String get terminologyHint => '輸入術語或縮寫（例如 ff、rit.）';

  @override
  String get terminologyNotFound => '找不到這個術語';

  @override
  String get drawerSignIn => 'Sign In';

  @override
  String get drawerSignInDesc => '登入以同步你的設定和紀錄';

  @override
  String get drawerAppearance => '外觀';

  @override
  String get drawerColorMode => 'Color Mode';

  @override
  String get drawerSupport => '支援';

  @override
  String get drawerUserGuide => 'User Guide';

  @override
  String get drawerBugReport => '問題回報';

  @override
  String get drawerThemeColor => '主題顏色';

  @override
  String get drawerBrightness => '明暗模式';

  @override
  String get colorBlack => '黑色';

  @override
  String get colorGray => '灰色';

  @override
  String get colorWhite => '白色';

  @override
  String get colorBlue => '藍色';

  @override
  String get colorPink => '粉紅';

  @override
  String get colorPurple => '紫色';

  @override
  String get colorGreen => '綠色';

  @override
  String get colorYellow => '黃色';

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
  String get drawerNotSignedIn => '尚未登入';

  @override
  String get drawerSignOut => '登出';

  @override
  String get loginTagline => '記錄你的每一次練習';

  @override
  String get loginGoogleButton => '使用 Google 登入';

  @override
  String get loginAppleButton => '使用 Apple 登入';

  @override
  String get loginDisplayName => '顯示名稱';

  @override
  String get loginPassword => '密碼';

  @override
  String get loginForgotPassword => '忘記密碼？';

  @override
  String get loginSignUp => '註冊';

  @override
  String get loginSignIn => '登入';

  @override
  String get loginAlreadyHaveAccount => '已有帳號？登入';

  @override
  String get loginNoAccount => '還沒有帳號？註冊';

  @override
  String get loginBenefitHint => '登入後可同步紀錄、加入樂團';

  @override
  String get loginSkip => '略過';

  @override
  String get loginFieldRequired => '此欄位為必填';

  @override
  String get loginInvalidEmail => '請輸入有效的電子郵件';

  @override
  String get loginPasswordTooShort => '密碼至少需要 6 個字元';

  @override
  String get calendarTitle => '行事曆';

  @override
  String get calendarSignInHint => '登入後可使用樂團群組功能';

  @override
  String get calendarAddEntry => '新增練習紀錄';

  @override
  String get calendarNoEntries => '這天沒有紀錄';

  @override
  String get calendarTabPersonal => '個人';

  @override
  String get calendarTabAll => '全部樂團';

  @override
  String get calendarEdit => '編輯';

  @override
  String get calendarDelete => '刪除';

  @override
  String get calendarUnitMin => '分鐘';

  @override
  String get calendarUnitHour => '小時';

  @override
  String get communityTitle => '社群';

  @override
  String get communityComingSoonTitle => '社群功能即將推出';

  @override
  String get communityComingSoonSub => '朋友練習動態、互相督促、分享進度';

  @override
  String get communityFriendsTitle => '朋友的練習';

  @override
  String get communityFriendsSub => '查看朋友今天練了什麼';

  @override
  String get communityLeaderboardTitle => '排行榜';

  @override
  String get communityLeaderboardSub => '本週練習時數排名';

  @override
  String get communityDevelopingNote => '功能持續開發中，敬請期待';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonCreate => '建立';

  @override
  String get commonSave => '儲存';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonRename => '重新命名';

  @override
  String get commonUndoWarning => '此操作無法復原。';

  @override
  String get recorderSearchHint => '搜尋資料夾';

  @override
  String get recorderAddFolder => '新增資料夾';

  @override
  String get recorderFolderName => '資料夾名稱';

  @override
  String get recorderNoResults => '找不到相關結果';

  @override
  String get recorderUncategorized => '未分類';

  @override
  String get recorderStatusRecording => '錄音中';

  @override
  String get recorderStatusIdle => '點擊開始錄音';

  @override
  String get recorderSaveTitle => '儲存錄音';

  @override
  String get recorderSaveHint => '輸入錄音名稱';

  @override
  String get recorderSaveFolder => '儲存至資料夾';

  @override
  String get recorderDiscard => '捨棄';

  @override
  String recorderFolderCount(int n) {
    return '$n 筆';
  }

  @override
  String get recorderFolderEmpty => '此資料夾沒有錄音';

  @override
  String get recorderFolderRenameTitle => '重新命名資料夾';

  @override
  String get recorderFolderDeleteTitle => '刪除資料夾';

  @override
  String recorderFolderDeleteBody(String name) {
    return '確定要刪除「$name」及其所有錄音？此操作無法復原。';
  }

  @override
  String get recorderMoveToFolder => '移至資料夾';

  @override
  String get recorderExportShare => '匯出 / 分享';

  @override
  String get recorderRenameTitle => '重新命名';

  @override
  String get recorderDeleteTitle => '刪除錄音';

  @override
  String recorderDeleteBody(String name) {
    return '確定要刪除「$name」？此操作無法復原。';
  }

  @override
  String metronomeBpmClamped(int bpm) {
    return 'BPM 已自動調整為 $bpm';
  }

  @override
  String get recorderSaveNameRequired => '請輸入錄音名稱';

 