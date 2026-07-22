import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'src/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @loginPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign into the application'**
  String get loginPageSubtitle;

  /// No description provided for @signUpPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up page'**
  String get signUpPageTitle;

  /// No description provided for @error404.
  ///
  /// In en, this message translates to:
  /// **'The record was not found'**
  String get error404;

  /// No description provided for @error401.
  ///
  /// In en, this message translates to:
  /// **'Authorization error occurred'**
  String get error401;

  /// No description provided for @error500.
  ///
  /// In en, this message translates to:
  /// **'Unknown error try again later'**
  String get error500;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in succesfully'**
  String get loginSuccess;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong'**
  String get loginError;

  /// No description provided for @loginButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonLabel;

  /// No description provided for @signUpButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButtonLabel;

  /// No description provided for @signUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sign up was a success'**
  String get signUpSuccess;

  /// No description provided for @signUpError.
  ///
  /// In en, this message translates to:
  /// **'Try again later'**
  String get signUpError;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get navLive;

  /// No description provided for @navOnDemand.
  ///
  /// In en, this message translates to:
  /// **'On Demand'**
  String get navOnDemand;

  /// No description provided for @navRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get navRadio;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @tabTitleOnDemand.
  ///
  /// In en, this message translates to:
  /// **'ON DEMAND'**
  String get tabTitleOnDemand;

  /// No description provided for @tabSubtitleOnDemand.
  ///
  /// In en, this message translates to:
  /// **'Watch FNDTV on demand'**
  String get tabSubtitleOnDemand;

  /// No description provided for @sectionOnDemand.
  ///
  /// In en, this message translates to:
  /// **'On Demand'**
  String get sectionOnDemand;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available'**
  String get noVideosAvailable;

  /// No description provided for @tabTitleHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get tabTitleHome;

  /// No description provided for @tabTitleLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get tabTitleLive;

  /// No description provided for @tabTitleRadio.
  ///
  /// In en, this message translates to:
  /// **'RADIO'**
  String get tabTitleRadio;

  /// No description provided for @tabTitleAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT FNDTV'**
  String get tabTitleAbout;

  /// No description provided for @tabSubtitleHome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FNDTV'**
  String get tabSubtitleHome;

  /// No description provided for @tabSubtitleLive.
  ///
  /// In en, this message translates to:
  /// **'Watch FNDTV Live Channels'**
  String get tabSubtitleLive;

  /// No description provided for @tabSubtitleRadio.
  ///
  /// In en, this message translates to:
  /// **'Listen to FNDTV Radio'**
  String get tabSubtitleRadio;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @sectionLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get sectionLiveNow;

  /// No description provided for @sectionChicagoTime.
  ///
  /// In en, this message translates to:
  /// **'Chicago time'**
  String get sectionChicagoTime;

  /// No description provided for @sectionRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get sectionRadio;

  /// No description provided for @sectionLiveTv.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get sectionLiveTv;

  /// No description provided for @badgeLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get badgeLive;

  /// No description provided for @badgeUsTime.
  ///
  /// In en, this message translates to:
  /// **'US TIME'**
  String get badgeUsTime;

  /// No description provided for @badgeOnAir.
  ///
  /// In en, this message translates to:
  /// **'ON AIR'**
  String get badgeOnAir;

  /// No description provided for @brandRadio.
  ///
  /// In en, this message translates to:
  /// **'FNDTV Radio'**
  String get brandRadio;

  /// No description provided for @noRadioChannel.
  ///
  /// In en, this message translates to:
  /// **'No radio channel available'**
  String get noRadioChannel;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @scheduleLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the schedule'**
  String get scheduleLoadError;

  /// No description provided for @noSchedule.
  ///
  /// In en, this message translates to:
  /// **'No schedule available'**
  String get noSchedule;

  /// No description provided for @channelsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load channels'**
  String get channelsLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @aboutWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What is FNDTV?'**
  String get aboutWhatTitle;

  /// No description provided for @aboutIntro1.
  ///
  /// In en, this message translates to:
  /// **'FNDTV is an IPTV / OTT platform accessible from anywhere in the world, for the family, the maintaining of Catholic Tradition, Christian Unity, Religious Freedom and Human Rights.'**
  String get aboutIntro1;

  /// No description provided for @aboutIntro2.
  ///
  /// In en, this message translates to:
  /// **'FNDTV is also made of religious Nuns, Friars, Priests and Tertiaries filled with energy and determination, towards God’s glory and the Evangelization, offering their lives for the Salvation of souls and making themselves available to the poorest of the poor and all those who suffer in their heart or in their body, with no distinction of social status, race, gender or creed.'**
  String get aboutIntro2;

  /// No description provided for @aboutIntro3.
  ///
  /// In en, this message translates to:
  /// **'Learn how to know them, through their television programs.'**
  String get aboutIntro3;

  /// No description provided for @aboutIntro4.
  ///
  /// In en, this message translates to:
  /// **'They dedicate themselves unreservedly towards offering this valuable content to you, day and night, no matter the weather or circumstances.'**
  String get aboutIntro4;

  /// No description provided for @aboutIntro5.
  ///
  /// In en, this message translates to:
  /// **'Share in their joy, peace and love of God which prompted them to create this TV Platform for you, your family, and in order to help you keep the Faith and uphold Christian Values, despite everything and everyone!'**
  String get aboutIntro5;

  /// No description provided for @aboutPlatform.
  ///
  /// In en, this message translates to:
  /// **'FNDTV PLATFORM'**
  String get aboutPlatform;

  /// No description provided for @aboutSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support FNDTV'**
  String get aboutSupportTitle;

  /// No description provided for @aboutDonatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Help FNDTV keep broadcasting. Tap below to donate:'**
  String get aboutDonatePrompt;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @donationOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the donation page'**
  String get donationOpenError;

  /// No description provided for @settingsBlueTheme.
  ///
  /// In en, this message translates to:
  /// **'Blue Theme'**
  String get settingsBlueTheme;

  /// No description provided for @settingsDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get settingsDarkTheme;
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
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
