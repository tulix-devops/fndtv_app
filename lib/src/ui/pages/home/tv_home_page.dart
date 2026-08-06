import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/core/constants/stb_radio_policy.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart';
import 'package:ui_kit/ui_kit.dart';

/// Home (TV) — dark 10-foot layout: red-accented section headers with a
/// horizontal rail of focusable channel cards for the selected language.
class TvHomePage extends StatelessWidget {
  final FndtvLanguage language;

  const TvHomePage({super.key, required this.language});

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

          final live =
              channelsForLanguage(state.contentList?['8']?.data, language);
          final mainLive = live.where((m) => !m.isTimeShift).toList();
          final timeShift = live.where((m) => m.isTimeShift).toList();
          // Spanish radio is hidden outright on the box, which also drops the
          // whole Radio section from Home for that locale — see
          // stb_radio_policy.
          final radio = visibleRadioChannels(
            channelsForLanguage(state.contentList?['10']?.data, language),
          );

          // A partial backend failure (one content type errors while the others
          // succeed) still reports Status.success, so we can land here with
          // nothing to show. Every section below is conditional, which would
          // otherwise leave the Column childless — a blank screen the user
          // can't distinguish from a hang. Say so instead.
          if (mainLive.isEmpty && timeShift.isEmpty && radio.isEmpty) {
            return ContentUnavailable(
              colors: colors,
              // TV paints on kTvBg (near-black); the UiKit palette's dark text
              // would be invisible there.
              titleColor: Colors.white,
              bodyColor: Colors.white70,
              iconColor: Colors.white38,
              onRetry: () => context
                  .read<ContentCubit>()
                  .getContentForMultipleTypes([8, 10, 17]),
            );
          }

          return FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 22, 44, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mainLive.isNotEmpty) ...[
                    TvSectionHeader(l.sectionLiveNow),
                    Expanded(
                      child: TvChannelRow(
                        channel: mainLive.first,
                        badge: l.badgeLive,
                        autofocus: true,
                        onTap: () => openLiveDetail(context, mainLive.first,
                            contentType: ContentType.television),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (timeShift.isNotEmpty) ...[
                    // The US feed is presented as live too — same heading and
                    // badge as the Europe row (was "Chicago time" / "US TIME").
                    TvSectionHeader(l.sectionLiveNow),
                    Expanded(
                      child: TvChannelRow(
                        channel: timeShift.first,
                        badge: l.badgeLive,
                        onTap: () => openLiveDetail(context, timeShift.first,
                            contentType: ContentType.television),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (radio.isNotEmpty) ...[
                    TvSectionHeader(l.sectionRadio),
                    Expanded(
                      child: TvChannelRow(
                        channel: radio.first,
                        badge: isRadioComingSoon(radio.first)
                            ? l.radioComingSoon
                            : l.badgeOnAir,
                        onTap: () => isRadioComingSoon(radio.first)
                            ? RadioComingSoonPage.open(context, radio.first)
                            : openLiveDetail(context, radio.first,
                                contentType: ContentType.radio),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
