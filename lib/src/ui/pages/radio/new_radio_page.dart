import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// Radio — large "now playing" hero for the selected language's radio channel.
/// The sparsest screen, so it leans on big art + an animated equalizer to fill
/// the space.
class NewRadioPage extends StatelessWidget {
  final FndtvLanguage language;

  const NewRadioPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final radios =
        FndtvChannels.radio.where((c) => c.language == language).toList();

    if (radios.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: Center(
          child: Text(
            'No radio channel available',
            style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    final channel = radios.first;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ON AIR pill
                const StatusPill(text: 'ON AIR', icon: Icons.circle),
                const SizedBox(height: 28),

                // Banner artwork
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(width: 3, color: const Color(0xFFFFE088)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 461 / 310,
                    child: Image.network(
                      channel.logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.mic_rounded,
                          size: 64,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Name
                Text(
                  channel.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'FNDTV Radio',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),

                // Big equalizer
                SizedBox(
                  height: 44,
                  child: EqualizerBars(color: colors.accent, height: 44, bars: 11),
                ),
                const SizedBox(height: 32),

                // Big play button
                GestureDetector(
                  onTap: () => openChannel(context, channel),
                  child: const RoundedPlayButton(size: 76, filled: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
