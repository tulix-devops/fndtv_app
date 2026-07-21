import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Live — the selected language's live channels from the API: Live TV (main)
/// and Chicago time (time-shift).
class MobileLivePage extends StatelessWidget {
  final FndtvLanguage language;

  const MobileLivePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final l = context.l;

    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (contentIsLoading(state)) return ContentLoading(colors: colors);
        if (state.status == Status.failure) {
          return ContentError(colors: colors);
        }

        // All live channels — Europe and US time alike — under a single
        // "En Direct" (live) section.
        final live =
            channelsForLanguage(state.contentList?['8']?.data, language);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            FndtvSectionHeader(l.sectionLiveNow),
            for (final channel in live) ...[
              LivePosterTile(channel: channel),
              const SizedBox(height: 22),
            ],
          ],
        );
      },
    );
  }
}
