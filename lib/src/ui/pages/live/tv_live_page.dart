import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart';
import 'package:ui_kit/ui_kit.dart';

/// Live (TV) — dark 10-foot layout: Live TV and Chicago-time channels as
/// focusable cards for the selected language.
class TvLivePage extends StatelessWidget {
  final FndtvLanguage language;

  const TvLivePage({super.key, required this.language});

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

          // All live channels — Europe and US time alike — are shown together
          // under a single "En Direct" (live) section.
          final live =
              channelsForLanguage(state.contentList?['8']?.data, language);

          return FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 22, 44, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvSectionHeader(l.sectionLiveNow),
                  for (final (index, channel) in live.indexed)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TvChannelRow(
                          channel: channel,
                          badge: l.badgeLive,
                          autofocus: index == 0,
                          onTap: () => openLiveDetail(context, channel,
                              contentType: ContentType.television),
                        ),
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
