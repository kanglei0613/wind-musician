import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'管樂手帳'**
  String get appName;

  /// No description provided for @navTuner.
  ///
  /// In zh, this message translates to:
  /// **'調音器'**
  String get navTuner;

  /// No description provided for @navRecorder.
  ///
  /// In zh, this message translates to:
  /// **'錄音'**
  String get navRecorder;

  /// No description provided for @navAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get navAnalysis;

  /// No description provided for @navSchedule.
  ///
  /// In zh, this message translates to:
  /// **'行程'**
  String get navSchedule;

  /// No description provided for @tunerInTune.
  ///
  /// In zh, this message translates to:
  /// **'準確'**
  String get tunerInTune;

  /// No description provided for @tunerSharp.
  ///
  /// In zh, this message translates to:
  /// **'偏高'**
  String get tunerSharp;

  /// No description provided for @tunerFlat.
  ///
  /// In zh, this message translates to:
  /// **'偏低'**
  String get tunerFlat;

  /// No description provided for @tunerReference.
  ///
  /// In zh, this message translates to:
  /// **'調音基準音高'**
  String get tunerReference;

  /// No description provided for @tunerReferenceCommon.
  ///
  /// In zh, this message translates to:
  /// **'常用設定'**
  String get tunerReferenceCommon;

  /// No description provided for @tunerSelectInstrument.
  ///
  /// In zh, this message translates to:
  /// **'選擇樂器'**
  String get tunerSelectInstrument;

  /// No description provided for @instrumentConcertPitch.
  ///
  /// In zh, this message translates to:
  /// **'Concert Pitch'**
  String get instrumentConcertPitch;

  /// No description provided for @instrumentFlute.
  ///
  /// In zh, this message translates to:
  /// **'長笛'**
  String get instrumentFlute;

  /// No description provided for @instrumentOboe.
  ///
  /// In zh, this message translates to:
  /// **'雙簧管'**
  String get instrumentOboe;

  /// No description provided for @instrumentBassoon.
  ///
  /// In zh, this message translates to:
  /// **'低音管'**
  String get instrumentBassoon;

  /// No description provided for @instrumentTrombone.
  ///
  /// In zh, this message translates to:
  /// **'長號'**
  String get instrumentTrombone;

  /// No description provided for @instrumentTuba.
  ///
  /// In zh, this message translates to:
  /// **'大號'**
  String get instrumentTuba;

  /// No description provided for @instrumentTrumpet.
  ///
  /// In zh, this message translates to:
  /// **'小號'**
  String get instrumentTrumpet;

  /// No description provided for @instrumentClarinet.
  ///
  /// In zh, this message translates to:
  /// **'單簧管'**
  String get instrumentClarinet;

  /// No description provided for @instrumentTenorSax.
  ///
  /// In zh, this message translates to:
  /// **'次中音薩克斯風'**
  String get instrumentTenorSax;

  /// No description provided for @instrumentEuphonium.
  ///
  /// In zh, this message translates to:
  /// **'上低音號'**
  String get instrumentEuphonium;

  /// No description provided for @instrumentBassClarinet.
  ///
  /// In zh, this message translates to:
  /// **'低音單簧管'**
  String get instrumentBassClarinet;

  /// No description provided for @instrumentAltoSax.
  ///
  /// In zh, this message translates to:
  /// **'中音薩克斯風'**
  String get instrumentAltoSax;

  /// No description provided for @instrumentBaritoneSax.
  ///
  /// In zh, this message translates to:
  /// **'上低音薩克斯風'**
  String get instrumentBaritoneSax;

  /// No description provided for @instrumentEbClarinet.
  ///
  /// In zh, this message translates to:
  /// **'Eb 單簧管'**
  String get instrumentEbClarinet;

  /// No description provided for @instrumentFrenchHorn.
  ///
  /// In zh, this message translates to:
  /// **'法國號'**
  String get instrumentFrenchHorn;

  /// No description provided for @instrumentEnglishHorn.
  ///
  /// In zh, this message translates to:
  /// **'英國號'**
  String get instrumentEnglishHorn;

  /// No description provided for @tunerDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get tunerDone;

  /// No description provided for @tunerCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get tunerCancel;

  /// No description provided for @metronomeInputBpm.
  ///
  /// In zh, this message translates to:
  /// **'輸入 BPM'**
  String get metronomeInputBpm;

  /// No description provided for @metronomeSection.
  ///
  /// In zh, this message translates to:
  /// **'段落練習'**
  String get metronomeSection;

  /// No description provided for @metronomeSectionAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增段落'**
  String get metronomeSectionAdd;

  /// No description provided for @metronomeSectionEnable.
  ///
  /// In zh, this message translates to:
  /// **'開啟段落練習模式，可設定多段不同拍號的練習循環。'**
  String get metronomeSectionEnable;

  /// No description provided for @metronomeSectionLabel.
  ///
  /// In zh, this message translates to:
  /// **'段落'**
  String get metronomeSectionLabel;

  /// No description provided for @metronomeMeasure.
  ///
  /// In zh, this message translates to:
  /// **'小節'**
  String get metronomeMeasure;

  /// No description provided for @terminologyTitle.
  ///
  /// In zh, this message translates to:
  /// **'音樂術語查詢'**
  String get terminologyTitle;

  /// No description provided for @terminologyHint.
  ///
  /// In zh, this message translates to:
  /// **'輸入術語或縮寫（例如 ff、rit.）'**
  String get terminologyHint;

  /// No description provided for @terminologyNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到這個術語'**
  String get terminologyNotFound;

  /// No description provided for @drawerSignIn.
  ///
  /// In zh, this message translates to:
  /// **'Sign In'**
  String get drawerSignIn;

  /// No description provided for @drawerSignInDesc.
  ///
  /// In zh, this message translates to:
  /// **'登入以同步你的設定和紀錄'**
  String get drawerSignInDesc;

  /// No description provided for @drawerAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外觀'**
  String get drawerAppearance;

  /// No description provided for @drawerColorMode.
  ///
  /// In zh, this message translates to:
  /// **'Color Mode'**
  String get drawerColorMode;

  /// No description provided for @drawerSupport.
  ///
  /// In zh, this message translates to:
  /// **'支援'**
  String get drawerSupport;

  /// No description provided for @drawerUserGuide.
  ///
  /// In zh, this message translates to:
  /// **'User Guide'**
  String get drawerUserGuide;

  /// No description provided for @drawerBugReport.
  ///
  /// In zh, this message translates to:
  /// **'問題回報'**
  String get drawerBugReport;

  /// No description provided for @drawerThemeColor.
  ///
  /// In zh, this message translates to:
  /// **'主題顏色'**
  String get drawerThemeColor;

  /// No description provided for @drawerBrightness.
  ///
  /// In zh, this message translates to:
  /// **'明暗模式'**
  String get drawerBrightness;

  /// No description provided for @colorBlack.
  ///
  /// In zh, this message translates to:
  /// **'黑色'**
  String get colorBlack;

  /// No description provided for @colorGray.
  ///
  /// In zh, this message translates to:
  /// **'灰色'**
  String get colorGray;

  /// No description provided for @colorWhite.
  ///
  /// In zh, this message translates to:
  /// **'白色'**
  String get colorWhite;

  /// No description provided for @colorBlue.
  ///
  /// In zh, this message translates to:
  /// **'藍色'**
  String get colorBlue;

  /// No description provided for @colorPink.
  ///
  /// In zh, this message translates to:
  /// **'粉紅'**
  String get colorPink;

  /// No description provided for @colorPurple.
  ///
  /// In zh, this message translates to:
  /// **'紫色'**
  String get colorPurple;

  /// No description provided for @colorGreen.
  ///
  /// In zh, this message translates to:
  /// **'綠色'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In zh, this message translates to:
  /// **'黃色'**
  String get colorYellow;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'語言'**
  String get settingsLanguage;

  /// No description provided for @settingsTunerReference.
  ///
  /// In zh, this message translates to:
  /// **'調音基準音高'**
  String get settingsTunerReference;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langJa.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get langJa;

  /// No description provided for @langKo.
  ///
  /// In zh, this message translates to:
  /// **'한국어'**
  String get langKo;

  /// No description provided for @errorGeneral.
  ///
  /// In zh, this message translates to:
  /// **'發生錯誤，請稍後再試'**
  String get errorGeneral;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'網路連線失敗'**
  String get errorNetwork;

  /// No description provided for @recorderTitle.
  ///
  /// In zh, this message translates to:
  /// **'錄音'**
  String get recorderTitle;

  /// No description provided for @recorderStart.
  ///
  /// In zh, this message translates to:
  /// **'開始錄音'**
  String get recorderStart;

  /// No description provided for @recorderStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get recorderStop;

  /// No description provided for @recorderNoRecordings.
  ///
  /// In zh, this message translates to:
  /// **'還沒有錄音紀錄'**
  String get recorderNoRecordings;

  /// No description provided for @analysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 分析'**
  String get analysisTitle;

  /// No description provided for @analysisStart.
  ///
  /// In zh, this message translates to:
  /// **'開始分析'**
  String get analysisStart;

  /// No description provided for @analysisLoading.
  ///
  /// In zh, this message translates to:
  /// **'分析中...'**
  String get analysisLoading;

  /// No description provided for @analysisMusicianLabel.
  ///
  /// In zh, this message translates to:
  /// **'選擇音樂家風格'**
  String get analysisMusicianLabel;

  /// No description provided for @scheduleTitle.
  ///
  /// In zh, this message translates to:
  /// **'行程'**
  String get scheduleTitle;

  /// No description provided for @scheduleAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增練習'**
  String get scheduleAdd;

  /// No description provided for @scheduleNoEvents.
  ///
  /// In zh, this message translates to:
  /// **'還沒有行程紀錄'**
  String get scheduleNoEvents;

  /// No description provided for @drawerNotSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'尚未登入'**
  String get drawerNotSignedIn;

  /// No description provided for @drawerSignOut.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get drawerSignOut;

  /// No description provided for @loginTagline.
  ///
  /// In zh, this message translates to:
  /// **'記錄你的每一次練習'**
  String get loginTagline;

  /// No description provided for @loginGoogleButton.
  ///
  /// In zh, this message translates to:
  /// **'使用 Google 登入'**
  String get loginGoogleButton;

  /// No description provided for @loginAppleButton.
  ///
  /// In zh, this message translates to:
  /// **'使用 Apple 登入'**
  String get loginAppleButton;

  /// No description provided for @loginDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'顯示名稱'**
  String get loginDisplayName;

  /// No description provided for @loginPassword.
  ///
  /// In zh, this message translates to:
  /// **'密碼'**
  String get loginPassword;

  /// No description provided for @loginForgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘記密碼？'**
  String get loginForgotPassword;

  /// No description provided for @loginSignUp.
  ///
  /// In zh, this message translates to:
  /// **'註冊'**
  String get loginSignUp;

  /// No description provided for @loginSignIn.
  ///
  /// In zh, this message translates to:
  /// **'登入'**
  String get loginSignIn;

  /// No description provided for @loginAlreadyHaveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已有帳號？登入'**
  String get loginAlreadyHaveAccount;

  /// No description provided for @loginNoAccount.
  ///
  /// In zh, this message translates to:
  /// **'還沒有帳號？註冊'**
  String get loginNoAccount;

  /// No description provided for @loginBenefitHint.
  ///
  /// In zh, this message translates to:
  /// **'登入後可同步紀錄、加入樂團'**
  String get loginBenefitHint;

  /// No description provided for @loginSkip.
  ///
  /// In zh, this message translates to:
  /// **'略過'**
  String get loginSkip;

  /// No description provided for @loginFieldRequired.
  ///
  /// In zh, this message translates to:
  /// **'此欄位為必填'**
  String get loginFieldRequired;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'請輸入有效的電子郵件'**
  String get loginInvalidEmail;

  /// No description provided for @loginPasswordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密碼至少需要 6 個字元'**
  String get loginPasswordTooShort;

  /// No description provided for @calendarTitle.
  ///
  /// In zh, this message translates to:
  /// **'行事曆'**
  String get calendarTitle;

  /// No description provided for @calendarSignInHint.
  ///
  /// In zh, this message translates to:
  /// **'登入後可使用樂團群組功能'**
  String get calendarSignInHint;

  /// No description provided for @calendarAddEntry.
  ///
  /// In zh, this message translates to:
  /// **'新增練習紀錄'**
  String get calendarAddEntry;

  /// No description provided for @calendarNoEntries.
  ///
  /// In zh, this message translates to:
  /// **'這天沒有紀錄'**
  String get calendarNoEntries;

  /// No description provided for @calendarTabPersonal.
  ///
  /// In zh, this message translates to:
  /// **'個人'**
  String get calendarTabPersonal;

  /// No description provided for @calendarTabAll.
  ///
  /// In zh, this message translates to:
  /// **'全部樂團'**
  String get calendarTabAll;

  /// No description provided for @calendarEdit.
  ///
  /// In zh, this message translates to:
  /// **'編輯'**
  String get calendarEdit;

  /// No description provided for @calendarDelete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get calendarDelete;

  /// No description provided for @calendarUnitMin.
  ///
  /// In zh, this message translates to:
  /// **'分鐘'**
  String get calendarUnitMin;

  /// No description provided for @calendarUnitHour.
  ///
  /// In zh, this message translates to:
  /// **'小時'**
  String get calendarUnitHour;

  /// No description provided for @communityTitle.
  ///
  /// In zh, this message translates to:
  /// **'社群'**
  String get communityTitle;

  /// No description provided for @communityComingSoonTitle.
  ///
  /// In zh, this message translates to:
  /// **'社群功能即將推出'**
  String get communityComingSoonTitle;

  /// No description provided for @communityComingSoonSub.
  ///
  /// In zh, this message translates to:
  /// **'朋友練習動態、互相督促、分享進度'**
  String get communityComingSoonSub;

  /// No description provided for @communityFriendsTitle.
  ///
  /// In zh, this message translates to:
  /// **'朋友的練習'**
  String get communityFriendsTitle;

  /// No description provided for @communityFriendsSub.
  ///
  /// In zh, this message translates to:
  /// **'查看朋友今天練了什麼'**
  String get communityFriendsSub;

  /// No description provided for @communityLeaderboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'排行榜'**
  String get communityLeaderboardTitle;

  /// No description provided for @communityLeaderboardSub.
  ///
  /// In zh, this message translates to:
  /// **'本週練習時數排名'**
  String get communityLeaderboardSub;

  /// No description provided for @communityDevelopingNote.
  ///
  /// In zh, this message translates to:
  /// **'功能持續開發中，敬請期待'**
  String get communityDevelopingNote;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'確認'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In zh, this message translates to:
  /// **'建立'**
  String get commonCreate;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get commonDelete;

  /// No description provided for @commonRename.
  ///
  /// In zh, this message translates to:
  /// **'重新命名'**
  String get commonRename;

  /// No description provided for @commonUndoWarning.
  ///
  /// In zh, this message translates to:
  /// **'此操作無法復原。'**
  String get commonUndoWarning;

  /// No description provided for @recorderSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜尋資料夾'**
  String get recorderSearchHint;

  /// No description provided for @recorderAddFolder.
  ///
  /// In zh, this message translates to:
  /// **'新增資料夾'**
  String get recorderAddFolder;

  /// No description provided for @recorderFolderName.
  ///
  /// In zh, this message translates to:
  /// **'資料夾名稱'**
  String get recorderFolderName;

  /// No description provided for @recorderNoResults.
  ///
  /// In zh, this message translates to:
  /// **'找不到相關結果'**
  String get recorderNoResults;

  /// No description provided for @recorderUncategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分類'**
  String get recorderUncategorized;

  /// No description provided for @recorderStatusRecording.
  ///
  /// In zh, this message translates to:
  /// **'錄音中'**
  String get recorderStatusRecording;

  /// No description provided for @recorderStatusIdle.
  ///
  /// In zh, this message translates to:
  /// **'點擊開始錄音'**
  String get recorderStatusIdle;

  /// No description provided for @recorderSaveTitle.
  ///
  /// In zh, this message translates to:
  /// **'儲存錄音'**
  String get recorderSaveTitle;

  /// No description provided for @recorderSaveHint.
  ///
  /// In zh, this message translates to:
  /// **'輸入錄音名稱'**
  String get recorderSaveHint;

  /// No description provided for @recorderSaveFolder.
  ///
  /// In zh, this message translates to:
  /// **'儲存至資料夾'**
  String get recorderSaveFolder;

  /// No description provided for @recorderDiscard.
  ///
  /// In zh, this message translates to:
  /// **'捨棄'**
  String get recorderDiscard;

  /// No description provided for @recorderFolderCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 筆'**
  String recorderFolderCount(int n);

  /// No description provided for @recorderFolderEmpty.
  ///
  /// In zh, this message translates to:
  /// **'此資料夾沒有錄音'**
  String get recorderFolderEmpty;

  /// No description provided for @recorderFolderRenameTitle.
  ///
  /// In zh, this message translates to:
  /// **'重新命名資料夾'**
  String get recorderFolderRenameTitle;

  /// No description provided for @recorderFolderDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'刪除資料夾'**
  String get recorderFolderDeleteTitle;

  /// No description provided for @recorderFolderDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'確定要刪除「{name}」及其所有錄音？此操作無法復原。'**
  String recorderFolderDeleteBody(String name);

  /// No description provided for @recorderMoveToFolder.
  ///
  /// In zh, this message translates to:
  /// **'移至資料夾'**
  String get recorderMoveToFolder;

  /// No description provided for @recorderExportShare.
  ///
  /// In zh, this message translates to:
  /// **'匯出 / 分享'**
  String get recorderExportShare;

  /// No description provided for @recorderRenameTitle.
  ///
  /// In zh, this message translates to:
  /// **'重新命名'**
  String get recorderRenameTitle;

  /// No description provided for @recorderDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'刪除錄音'**
  String get recorderDeleteTitle;

  /// No description provided for @recorderDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'確定要刪除「{name}」？此操作無法復原。'**
  String recorderDeleteBody(String name);

  /// No description provided for @metronomeBpmClamped.
  ///
  /// In zh, this message translates to:
  /// **'BPM 已自動調整為 {bpm}'**
  String metronomeBpmClamped(int bpm);

  /// No description provided for @recorderSaveNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'請輸入錄音名稱'**
  String get recorderSaveNameRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
