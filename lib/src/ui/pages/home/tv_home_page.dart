import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
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
          final radio =
              channelsForLanguage(state.contentList?['10']?.data, language);

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
                    TvSectionHeader(l.sectionChicagoTime),
                    Expanded(
                      child: TvChannelRow(
                        channel: timeShift.first,
                        badge: l.badgeUsTime,
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
                        badge: l.badgeOnAir,
                        onTap: () => openLiveDetail(context, radio.first,
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
