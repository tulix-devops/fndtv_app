import 'package:flutter/material.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Live — editorial sections (Live TV / Radio / Chicago time), each showing the
/// selected language's channel.
class NewLivePage extends StatelessWidget {
  final FndtvLanguage language;

  const NewLivePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    final liveTv =
        FndtvChannels.liveTv.where((c) => c.language == language).toList();
    final timeShift =
        FndtvChannels.timeShift.where((c) => c.language == language).toList();

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (liveTv.isNotEmpty) ...[
            const FndtvSectionHeader('Live TV'),
            LivePosterTile(channel: liveTv.first),
            const SizedBox(height: 22),
          ],
          if (timeShift.isNotEmpty) ...[
            const FndtvSectionHeader('Chicago time'),
            LivePosterTile(channel: timeShift.first, badge: 'US TIME'),
          ],
        ],
      ),
    );
  }
}
