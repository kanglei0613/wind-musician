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
