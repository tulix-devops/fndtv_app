// Which radio channels the app shows, and whether they play.
//
// CLIENT DECISION, 2026-08-06. Radio has not actually launched: the "radio"
// entries the backend returns are the TELEVISION audio track relabelled
// (`…/itv04088/tracks-a1/mono.ts.m3u8`), not a radio service with its own
// schedule. So:
//
//  * Spanish — hidden completely, no mention anywhere. Not planned near term.
//  * French / English — the entry stays exactly where it is, but nothing plays;
//    it reads "Coming Soon". Keeping the entry point visible is the whole
//    point: when the real schedule is ready it should already have a home.
//
// THIS BELONGS IN THE BACKEND, AND SHOULD MOVE THERE. Dropping Spanish from
// `/api/content/10/list` and flagging the rest would make launching radio a
// backend change every client picks up immediately — precisely the "there right
// away" the client asked for. Done here instead, turning radio on costs an app
// release and a store review.
//
// Keyed on `details.language` rather than id: ids are NOT stable. The same
// three channels returned 107445197/1891938906/685382514 one morning and
// 473637054/826003094/1243958389 the same afternoon. An id-keyed filter would
// fail OPEN when they rotate — Spanish reappearing, or the audio starting up
// again — the wrong direction for a client instruction.
//
// Mirrors `stb_radio_policy.dart` on the set-top-box branch; the two should be
// switched on together when radio launches.

import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_kit/ui_kit.dart';

/// Languages with no radio presence at all.
const Set<String> _kHiddenRadioLanguages = {'spanish'};

String _language(LiveModel channel) =>
    (channel.details?.language ?? '').trim().toLowerCase();

/// True when this radio channel must not appear anywhere.
bool isRadioHidden(LiveModel channel) =>
    _kHiddenRadioLanguages.contains(_language(channel));

/// True when the channel is shown but must not play.
///
/// Everything still visible is "coming soon" today; when a language genuinely
/// launches, drop it from [_kHiddenRadioLanguages] handling here and it starts
/// playing with no other change.
bool isRadioComingSoon(LiveModel channel) => !isRadioHidden(channel);

/// Applies the visibility rule to a fetched radio list.
List<LiveModel> visibleRadioChannels(List<LiveModel> radios) =>
    radios.where((c) => !isRadioHidden(c)).toList();

/// Whether the Radio tab should exist at all for [language].
///
/// Keyed on the LANGUAGE rather than on the fetched list on purpose. Deriving it
/// from content would mean the tab is absent while the first request is in
/// flight and then appears when it lands, shifting every index after it
/// mid-interaction. The policy is static, so this can be answered before any
/// network call.
///
/// "No mention of it" was the client's wording for Spanish: hiding the channel
/// but leaving a Radio tab that says "no radio channel available" is still a
/// mention, and reads as broken rather than deliberate.
bool isRadioAvailableForLanguage(FndtvLanguage language) =>
    !_kHiddenRadioLanguages.contains(language.label.toLowerCase());

/// Shown instead of starting playback, so the control is never a dead press.
class RadioComingSoonSheet extends StatelessWidget {
  const RadioComingSoonSheet({super.key, required this.channelTitle});

  final String channelTitle;

  static Future<void> show(BuildContext context, LiveModel channel) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => RadioComingSoonSheet(channelTitle: channel.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final colors = context.uiKitColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE088),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded,
                color: Color(0xFF7A2A16), size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            channelTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.radioComingSoonTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.radioComingSoonBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(fontSize: 14, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
