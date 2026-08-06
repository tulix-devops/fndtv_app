import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_kit/ui_kit.dart';

/// Home — editorial layout from the live API. Shows the selected language's
/// live channels (main + Chicago time), then its radio.
class MobileHomePage extends StatelessWidget {
  final FndtvLanguage language;

  const MobileHomePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final l = context.l;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
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

          // Mobile layout — original poster tiles, no focus wiring.
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (mainLive.isNotEmpty) ...[
                FndtvSectionHeader(l.sectionLiveNow),
                LivePosterTile(channel: mainLive.first),
                const SizedBox(height: 22),
              ],
              if (timeShift.isNotEmpty) ...[
                FndtvSectionHeader(l.sectionLiveNow),
                LivePosterTile(channel: timeShift.first, badge: l.badgeLive),
                const SizedBox(height: 22),
              ],
              if (radio.isNotEmpty) ...[
                FndtvSectionHeader(l.sectionRadio),
                RadioRowCard(channel: radio.first),
              ],
            ],
          );
        },
      ),
    );
  }
}
