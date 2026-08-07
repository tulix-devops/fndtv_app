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

  /// No description provided for @tabTitleOnDemand.
  ///
  /// In en, this message translates to:
  /// **'ON DEMAND'**
  String get tabTitleOnDemand;

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

  /// No description provided for @tabSubtitleOnDemand.
  ///
  /// In en, this message translates to:
  /// **'Movies and shows on demand'**
  String get tabSubtitleOnDemand;

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

  /// No description provided for @navUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get navUpdates;

  /// No description provided for @updatesChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updatesChecking;

  /// No description provided for @updatesUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get updatesUpToDate;

  /// No description provided for @updatesNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Update did not install'**
  String get updatesNotInstalled;

  /// No description provided for @updatesNotInstalledHint.
  ///
  /// In en, this message translates to:
  /// **'The previous version is still running. The install may have been cancelled, or the box refused it.'**
  String get updatesNotInstalledHint;

  /// No description provided for @updatesBlockedDowngrade.
  ///
  /// In en, this message translates to:
  /// **'The box refused this build because its version is not newer than the one installed.'**
  String get updatesBlockedDowngrade;

  /// No description provided for @updatesInstallCancelled.
  ///
  /// In en, this message translates to:
  /// **'The installation was cancelled.'**
  String get updatesInstallCancelled;

  /// No description provided for @updatesBlockedSignature.
  ///
  /// In en, this message translates to:
  /// **'This build is signed with a different key than the one installed. The update package needs rebuilding with the correct signing key.'**
  String get updatesBlockedSignature;

  /// No description provided for @updatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updatesAvailable;

  /// No description provided for @updatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get updatesUnavailable;

  /// No description provided for @updatesDownload.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get updatesDownload;

  /// No description provided for @updatesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get updatesRetry;

  /// No description provided for @updatesDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get updatesDownloading;

  /// No description provided for @updatesDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get updatesDownloaded;

  /// No description provided for @updatesInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updatesInstall;

  /// No description provided for @updatesInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get updatesInstalling;

  /// No description provided for @updatesInProgress.
  ///
  /// In en, this message translates to:
  /// **'Update in progress'**
  String get updatesInProgress;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @sectionLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get sectionLiveNow;

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

  /// No description provided for @sectionOnDemand.
  ///
  /// In en, this message translates to:
  /// **'On Demand'**
  String get sectionOnDemand;

  /// No description provided for @badgeLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get badgeLive;

  /// No description provided for @badgeOnAir.
  ///
  /// In en, this message translates to:
  /// **'ON AIR'**
  String get badgeOnAir;

  /// No description provided for @badgeNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get badgeNow;

  /// No description provided for @sectionSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get sectionSchedule;

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

  /// No description provided for @contentUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get contentUnavailableTitle;

  /// No description provided for @contentUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'We are having a temporary issue loading content. Please try again in a moment.'**
  String get contentUnavailableBody;

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

  /// No description provided for @donateScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with your phone to donate'**
  String get donateScanHint;

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

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsScreenSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen Size'**
  String get settingsScreenSizeTitle;

  /// No description provided for @settingsScreenSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resize the picture to fit your TV'**
  String get settingsScreenSizeSubtitle;

  /// No description provided for @settingsScreenSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Use the arrows to resize · OK saves · Back cancels'**
  String get settingsScreenSizeHint;

  /// No description provided for @settingsScreenSizeReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to 100%'**
  String get settingsScreenSizeReset;

  /// No description provided for @settingsScreenSizeWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get settingsScreenSizeWidth;

  /// No description provided for @settingsScreenSizeHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsScreenSizeHeight;

  /// No description provided for @settingsScreenSizeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsScreenSizeSave;

  /// No description provided for @settingsScreenSizeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsScreenSizeCancel;

  /// No description provided for @settingsScreenSizeAxisWidth.
  ///
  /// In en, this message translates to:
  /// **'width'**
  String get settingsScreenSizeAxisWidth;

  /// No description provided for @settingsScreenSizeAxisHeight.
  ///
  /// In en, this message translates to:
  /// **'height'**
  String get settingsScreenSizeAxisHeight;

  /// No description provided for @settingsScreenSizeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsScreenSizeSaved;

  /// No description provided for @radioComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get radioComingSoon;

  /// No description provided for @radioComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio is coming soon'**
  String get radioComingSoonTitle;

  /// No description provided for @radioComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Our radio schedule is being prepared. It will appear here as soon as it is ready.'**
  String get radioComingSoonBody;

  /// No description provided for @navNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get navNetwork;

  /// No description provided for @networkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkTitle;

  /// No description provided for @networkConnectionCard.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get networkConnectionCard;

  /// No description provided for @networkModeWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get networkModeWifi;

  /// No description provided for @networkModeWired.
  ///
  /// In en, this message translates to:
  /// **'Wired'**
  String get networkModeWired;

  /// No description provided for @networkStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get networkStatusLabel;

  /// No description provided for @networkStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get networkStatusConnected;

  /// No description provided for @networkStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get networkStatusOffline;

  /// No description provided for @networkSsid.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkSsid;

  /// No description provided for @networkIp.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get networkIp;

  /// No description provided for @networkEthernetCard.
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get networkEthernetCard;

  /// No description provided for @networkEthernetLinked.
  ///
  /// In en, this message translates to:
  /// **'Cable connected'**
  String get networkEthernetLinked;

  /// No description provided for @networkEthernetNoCable.
  ///
  /// In en, this message translates to:
  /// **'No cable detected'**
  String get networkEthernetNoCable;

  /// No description provided for @networkDeviceCard.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get networkDeviceCard;

  /// No description provided for @networkDeviceMac.
  ///
  /// In en, this message translates to:
  /// **'MAC address'**
  String get networkDeviceMac;

  /// No description provided for @networkDeviceSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get networkDeviceSerial;

  /// No description provided for @networkDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get networkDeviceId;

  /// No description provided for @networkDeviceVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get networkDeviceVersion;

  /// No description provided for @networkAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available networks'**
  String get networkAvailable;

  /// No description provided for @networkScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get networkScan;

  /// No description provided for @networkScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get networkScanning;

  /// No description provided for @networkNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No networks found'**
  String get networkNoneFound;

  /// No description provided for @networkPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Wi-Fi password'**
  String get networkPasswordTitle;

  /// No description provided for @networkPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get networkPasswordHint;

  /// No description provided for @networkConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get networkConnect;

  /// No description provided for @networkConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get networkConnecting;

  /// No description provided for @networkJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect — check the password'**
  String get networkJoinFailed;

  /// No description provided for @networkRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get networkRetry;

  /// No description provided for @networkWiredWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'No cable detected'**
  String get networkWiredWarnTitle;

  /// No description provided for @networkWiredWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Switching to wired now will take the box offline until a cable is plugged in. Continue?'**
  String get networkWiredWarnBody;

  /// No description provided for @networkWiredWarnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch anyway'**
  String get networkWiredWarnConfirm;

  /// No description provided for @networkWiredWarnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get networkWiredWarnCancel;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get offlineTitle;

  /// No description provided for @offlineCta.
  ///
  /// In en, this message translates to:
  /// **'Set up network'**
  String get offlineCta;

  /// No description provided for @kioskLockTitle.
  ///
  /// In en, this message translates to:
  /// **'This device is locked'**
  String get kioskLockTitle;

  /// No description provided for @kioskLockMessage.
  ///
  /// In en, this message translates to:
  /// **'Please contact support to restore access.'**
  String get kioskLockMessage;
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
