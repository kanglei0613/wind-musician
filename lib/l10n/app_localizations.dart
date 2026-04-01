import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
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

  /// No description provided for @tunerTitle.
  ///
  /// In zh, this message translates to:
  /// **'調音器'**
  String get tunerTitle;

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
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

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
