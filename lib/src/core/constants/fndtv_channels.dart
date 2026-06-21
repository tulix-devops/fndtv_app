import 'package:commons/commons.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/source_model.dart';

/// Static FNDTV channel definitions.
///
/// These are hard-coded constants used **before the backend API is ready**.
/// Once the API is available, the same [LiveModel] shape can be returned by the
/// repository and these constants can be dropped (or kept as a fallback).
///
/// There are three groups of channels, each available in French / English /
/// Spanish:
///  * [FndtvChannelGroup.liveTv]    – main live TV streams (EPG in French time)
///  * [FndtvChannelGroup.radio]     – audio-only streams
///  * [FndtvChannelGroup.timeShift] – Chicago/US-time time-shifted streams

/// Spoken language of a channel.
enum FndtvLanguage {
  french('French', 'fr', 'FR'),
  english('English', 'en', 'GB'),
  spanish('Spanish', 'sp', 'ES');

  const FndtvLanguage(this.label, this.code, this.countryCode);

  /// Human readable label, e.g. `French`.
  final String label;

  /// Short code used in logo file names / EPG lookups, e.g. `fr`.
  final String code;

  /// ISO country code used to render the flag (French→FR, English→GB,
  /// Spanish→ES).
  final String countryCode;

  /// App UI locale code (French→`fr`, English→`en`, Spanish→`es`).
  /// Note this differs from [code] for Spanish (`sp` vs `es`).
  String get localeCode => switch (this) {
        FndtvLanguage.french => 'fr',
        FndtvLanguage.english => 'en',
        FndtvLanguage.spanish => 'es',
      };

  /// Endonym shown in the language picker regardless of the active UI locale.
  String get endonym => switch (this) {
        FndtvLanguage.french => 'Français',
        FndtvLanguage.english => 'English',
        FndtvLanguage.spanish => 'Español',
      };

  /// Resolves a UI locale code (`fr` / `en` / `es`) back to a [FndtvLanguage],
  /// defaulting to French.
  static FndtvLanguage fromLocaleCode(String code) => switch (code) {
        'en' => FndtvLanguage.english,
        'es' => FndtvLanguage.spanish,
        _ => FndtvLanguage.french,
      };
}

/// Filters API channels ([LiveModel]) to those matching [lang] via
/// `details.language` ("French"/"English"/"Spanish").
List<LiveModel> channelsForLanguage(List<LiveModel>? items, FndtvLanguage lang) {
  if (items == null) return const [];
  final code = lang.label.toLowerCase();
  return items
      .where((m) => (m.details?.language ?? '').toLowerCase() == code)
      .toList();
}

/// Which group a channel belongs to.
enum FndtvChannelGroup {
  liveTv('Live TV'),
  radio('Radio'),
  timeShift('US Time');

  const FndtvChannelGroup(this.label);

  /// Section header label shown in the UI.
  final String label;
}

/// A single FNDTV channel, defined as a constant until the API exists.
class FndtvChannel {
  const FndtvChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    required this.logoUrl,
    required this.language,
    required this.group,
    required this.epgLanguageCode,
    required this.epgTimeZone,
  });

  /// Stable unique id (also used as [LiveModel.id]).
  final int id;

  /// Display name, e.g. `FNDTV - French`.
  final String name;

  /// HLS (`.m3u8`) playback URL.
  final String streamUrl;

  /// Remote logo / poster URL.
  final String logoUrl;

  /// Spoken language of the channel.
  final FndtvLanguage language;

  /// Group the channel belongs to.
  final FndtvChannelGroup group;

  /// Language the EPG data is in (matches [FndtvLanguage.code]).
  final String epgLanguageCode;

  /// IANA timezone the EPG schedule should be displayed in.
  ///
  /// Live & radio channels use French time (`Europe/Paris`); the time-shift
  /// channels use Chicago/US time (`America/Chicago`).
  final String epgTimeZone;

  /// Whether this is an audio-only (radio) channel.
  bool get isRadio => group == FndtvChannelGroup.radio;

  /// [ContentType] used when opening this channel in the player.
  ContentType get contentType =>
      isRadio ? ContentType.radio : ContentType.television;

  /// Converts this constant into the [LiveModel] shape the existing screens
  /// and the video player already understand.
  LiveModel toLiveModel() {
    return LiveModel(
      id: id,
      typeId: contentType.value,
      type: isRadio ? 'radio' : 'television',
      title: name,
      images: ImagesModel(
        poster: logoUrl,
        banner: logoUrl,
        thumbnail: logoUrl,
      ),
      sources: SourceModel(
        primary: streamUrl,
        hls: streamUrl,
      ),
      live: true,
      isPermanent: true,
    );
  }
}

/// Base URL all channel logos are served from.
const String _logoBase = 'https://fndtv.tulix.tv/img/logos';

/// EPG timezones.
const String _frenchTimeZone = 'Europe/Paris';
const String _usTimeZone = 'America/Chicago';

/// All FNDTV channels grouped and ready to use before the API exists.
class FndtvChannels {
  const FndtvChannels._();

  /// Main live TV channels. EPG is delivered in French time.
  static const List<FndtvChannel> liveTv = [
    FndtvChannel(
      id: 4088,
      name: 'FNDTV - French',
      streamUrl: 'https://rpn3.bozztv.com/dvrfl04/itv04088/index.m3u8',
      logoUrl: '$_logoBase/fndtv-fr.png',
      language: FndtvLanguage.french,
      group: FndtvChannelGroup.liveTv,
      epgLanguageCode: 'fr',
      epgTimeZone: _frenchTimeZone,
    ),
    FndtvChannel(
      id: 4091,
      name: 'FNDTV - English',
      streamUrl: 'https://rpn3.bozztv.com/dvrfl04/itv04091/index.m3u8',
      logoUrl: '$_logoBase/fndtv-en.png',
      language: FndtvLanguage.english,
      group: FndtvChannelGroup.liveTv,
      epgLanguageCode: 'en',
      epgTimeZone: _frenchTimeZone,
    ),
    FndtvChannel(
      id: 4092,
      name: 'FNDTV - Spanish',
      streamUrl: 'https://rpn3.bozztv.com/dvrfl04/itv04092/index.m3u8',
      logoUrl: '$_logoBase/fndtv-sp.png',
      language: FndtvLanguage.spanish,
      group: FndtvChannelGroup.liveTv,
      epgLanguageCode: 'sp',
      epgTimeZone: _frenchTimeZone,
    ),
  ];

  /// Audio-only radio channels.
  static const List<FndtvChannel> radio = [
    FndtvChannel(
      id: 14088,
      name: 'FNDTV Radio - French',
      streamUrl:
          'https://rpn3.bozztv.com/fndtv/itv04088/tracks-a1/mono.ts.m3u8',
      logoUrl: '$_logoBase/fndtv-fr-audio.png',
      language: FndtvLanguage.french,
      group: FndtvChannelGroup.radio,
      epgLanguageCode: 'fr',
      epgTimeZone: _frenchTimeZone,
    ),
    FndtvChannel(
      id: 14091,
      name: 'FNDTV Radio - English',
      streamUrl:
          'https://rpn3.bozztv.com/fndtv/itv04091/tracks-a1/mono.ts.m3u8',
      logoUrl: '$_logoBase/fndtv-en-audio.png',
      language: FndtvLanguage.english,
      group: FndtvChannelGroup.radio,
      epgLanguageCode: 'en',
      epgTimeZone: _frenchTimeZone,
    ),
    FndtvChannel(
      id: 14092,
      name: 'FNDTV Radio - Spanish',
      streamUrl:
          'https://rpn3.bozztv.com/fndtv/itv04092/tracks-a1/mono.ts.m3u8',
      logoUrl: '$_logoBase/fndtv-sp-audio.png',
      language: FndtvLanguage.spanish,
      group: FndtvChannelGroup.radio,
      epgLanguageCode: 'sp',
      epgTimeZone: _frenchTimeZone,
    ),
  ];

  /// Chicago/US-time time-shifted channels.
  ///
  /// Their EPG can be derived from the matching live channel's French-time EPG
  /// shifted into [_usTimeZone].
  static const List<FndtvChannel> timeShift = [
    FndtvChannel(
      id: 24088,
      name: 'FNDTV - French (US Time)',
      streamUrl:
          'https://rpn3.bozztv.com/fndtv-tshift/itv04088-tshift/index.m3u8',
      logoUrl: '$_logoBase/fndtv-fr-time.png',
      language: FndtvLanguage.french,
      group: FndtvChannelGroup.timeShift,
      epgLanguageCode: 'fr',
      epgTimeZone: _usTimeZone,
    ),
    FndtvChannel(
      id: 24091,
      name: 'FNDTV - English (US Time)',
      streamUrl:
          'https://rpn3.bozztv.com/fndtv-tshift/itv04091-tshift/index.m3u8',
      logoUrl: '$_logoBase/fndtv-en-time.png',
      language: FndtvLanguage.english,
      group: FndtvChannelGroup.timeShift,
      epgLanguageCode: 'en',
      epgTimeZone: _usTimeZone,
    ),
    FndtvChannel(
      id: 24092,
      name: 'FNDTV - Spanish (US Time)',
      streamUrl:
          'https://rpn3.bozztv.com/fndtv-tshift/itv04092-tshift/index.m3u8',
      logoUrl: '$_logoBase/fndtv-sp-time.png',
      language: FndtvLanguage.spanish,
      group: FndtvChannelGroup.timeShift,
      epgLanguageCode: 'sp',
      epgTimeZone: _usTimeZone,
    ),
  ];

  /// All channels in display order (Live TV → Radio → US Time).
  static const List<FndtvChannel> all = [
    ...liveTv,
    ...radio,
    ...timeShift,
  ];

  /// Channel groups in the order they should be shown in the UI.
  static const List<FndtvChannelGroup> orderedGroups = [
    FndtvChannelGroup.liveTv,
    FndtvChannelGroup.radio,
    FndtvChannelGroup.timeShift,
  ];

  /// Returns the channels belonging to [group].
  static List<FndtvChannel> byGroup(FndtvChannelGroup group) {
    switch (group) {
      case FndtvChannelGroup.liveTv:
        return liveTv;
      case FndtvChannelGroup.radio:
        return radio;
      case FndtvChannelGroup.timeShift:
        return timeShift;
    }
  }
}
