import 'package:flutter/material.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Home — editorial layout. Shows all of the selected language's live channels
/// (main Live + Chicago time), then its radio. No API / metadata required.
class NewHomePage extends StatelessWidget {
  final FndtvLanguage language;

  const NewHomePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final liveTv =
        FndtvChannels.liveTv.where((c) => c.language == language).toList();
    final timeShift =
        FndtvChannels.timeShift.where((c) => c.language == language).toList();
    final radio =
        FndtvChannels.radio.where((c) => c.language == language).toList();

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (liveTv.isNotEmpty) ...[
            const FndtvSectionHeader('Live now'),
            LivePosterTile(channel: liveTv.first),
            const SizedBox(height: 22),
          ],
          if (timeShift.isNotEmpty) ...[
            const FndtvSectionHeader('Chicago time'),
            LivePosterTile(channel: timeShift.first, badge: 'US TIME'),
            const SizedBox(height: 22),
          ],
          if (radio.isNotEmpty) ...[
            const FndtvSectionHeader('Radio'),
            RadioRowCard(channel: radio.first),
          ],
        ],
      ),
    );
  }
}
