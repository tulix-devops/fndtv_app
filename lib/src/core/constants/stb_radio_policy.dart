// Which radio channels the set-top box shows, and whether they play.
//
// CLIENT DECISION, 2026-08-06. Radio has not actually launched: the three
// "radio" entries the backend returns are the TELEVISION audio track relabelled
// (`…/itv04088/tracks-a1/mono.ts.m3u8`), not a radio service with its own
// schedule. So:
//
//  * Spanish — hidden completely, no mention anywhere. Not planned near term.
//  * French / English — the tile stays exactly where it is, but nothing plays;
//    it reads "Coming Soon". Keeping the entry point visible is the whole
//    point: when the real schedule is ready it should already have a home.
//
// THIS BELONGS IN THE BACKEND, AND SHOULD MOVE THERE. Dropping Spanish from
// `/api/content/10/list` and flagging the rest would make launching radio a
// backend change every box picks up immediately — precisely the "there right
// away" the client asked for. Done here instead, turning radio on costs an app
// release, a QA cycle and an OTA to the fleet.
//
// Keyed on `details.language` rather than id: ids are NOT stable. The same
// three channels returned 107445197/1891938906/685382514 one morning and
// 473637054/826003094/1243958389 the same afternoon. An id-keyed filter would
// fail OPEN when they rotate — Spanish reappearing, or the audio starting up
// again — the wrong direction for a client instruction.

import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:ui_kit/ui_kit.dart';

/// Languages with no radio presence at all.
const Set<String> _kHiddenRadioLanguages = {'spanish'};

bool _isStb() => appFlavor == 'stb';

String _language(LiveModel channel) =>
    (channel.details?.language ?? '').trim().toLowerCase();

/// True when this radio channel must not appear anywhere.
bool isRadioHidden(LiveModel channel) =>
    _isStb() && _kHiddenRadioLanguages.contains(_language(channel));

/// True when the channel is shown but must not play.
///
/// Everything still visible is "coming soon" today; when a language genuinely
/// launches, drop it from here and it starts playing with no other change.
bool isRadioComingSoon(LiveModel channel) =>
    _isStb() && !isRadioHidden(channel);

/// Applies the visibility rule to a fetched radio list.
List<LiveModel> visibleRadioChannels(List<LiveModel> radios) =>
    radios.where((c) => !isRadioHidden(c)).toList();

/// Whether the Radio nav tab should exist at all for [language].
///
/// Keyed on the LANGUAGE rather than on the fetched list on purpose. Deriving it
/// from content would mean the tab is absent while the first request is in
/// flight and then pops into the rail when it lands — a nav item appearing
/// under the viewer's cursor, and every index after it shifting mid-interaction.
/// The policy is static, so this can be answered before any network call.
///
/// "No mention of it" was the client's wording for Spanish: hiding the channel
/// but leaving a Radio tab that says "no radio channel available" is still a
/// mention, and reads as broken rather than deliberate.
bool isRadioAvailableForLanguage(FndtvLanguage language) =>
    !_isStb() || !_kHiddenRadioLanguages.contains(language.label.toLowerCase());

/// Full-screen stand-in shown instead of the player.
///
/// A real screen rather than a toast so the OK button is never a dead press,
/// and Back returns to the list as usual.
class RadioComingSoonPage extends StatelessWidget {
  const RadioComingSoonPage({super.key, required this.channelTitle});

  final String channelTitle;

  static void open(BuildContext context, LiveModel channel) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RadioComingSoonPage(channelTitle: channel.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F13),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_rounded, color: context.uiColors.primary, size: 72),
              const SizedBox(height: 24),
              Text(
                channelTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.radioComingSoonTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 720,
                child: Text(
                  l.radioComingSoonBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
