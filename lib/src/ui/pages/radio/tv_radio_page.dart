import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/core/constants/stb_radio_policy.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart';
import 'package:ui_kit/ui_kit.dart';

/// Radio (TV) — dark 10-foot layout with the selected language's radio channel
/// as a focusable card.
class TvRadioPage extends StatelessWidget {
  final FndtvLanguage language;

  const TvRadioPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final l = context.l;

    return Scaffold(
      backgroundColor: kTvBg,
      body: BlocBuilder<ContentCubit, ContentState>(
        builder: (context, state) {
          if (contentIsLoading(state)) return ContentLoading(colors: colors);
          if (state.status == Status.failure) {
            return ContentError(colors: colors);
          }

          // Spanish radio is hidden outright on the box — see stb_radio_policy.
          final radios = visibleRadioChannels(
            channelsForLanguage(state.contentList?['10']?.data, language),
          );
          if (radios.isEmpty) {
            return Center(
              child: Text(
                l.noRadioChannel,
                style: GoogleFonts.sora(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 22, 44, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvSectionHeader(l.sectionRadio),
                  for (final channel in radios)
                    Expanded(
                      child: TvChannelRow(
                        channel: channel,
                        // Not on air — nothing is broadcasting yet.
                        badge: isRadioComingSoon(channel)
                            ? l.radioComingSoon
                            : l.badgeOnAir,
                        autofocus: channel == radios.first,
                        onTap: () => isRadioComingSoon(channel)
                            ? RadioComingSoonPage.open(context, channel)
                            : openLiveDetail(context, channel,
                                contentType: ContentType.radio),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
