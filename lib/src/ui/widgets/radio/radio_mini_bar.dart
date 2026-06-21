import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/audio/radio_player_service.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:ui_kit/ui_kit.dart';

/// Spotify-style persistent mini-player. Sits above the bottom nav and stays
/// visible across all tabs while a radio channel is loaded. Hidden when nothing
/// is playing.
class RadioMiniBar extends StatelessWidget {
  const RadioMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return ValueListenableBuilder<LiveModel?>(
      valueListenable: RadioPlayerService.instance.currentChannel,
      builder: (context, channel, _) {
        if (channel == null) return const SizedBox.shrink();

        final art = channel.images.getThumbnail();
        final hasArt = art.startsWith('http');

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.accent,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: hasArt
                      ? Image.network(
                          art,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackArt,
                        )
                      : _fallbackArt,
                ),
              ),
              const SizedBox(width: 12),
              // Title + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      channel.title,
                      style: GoogleFonts.sora(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.l.brandRadio,
                      style: GoogleFonts.sora(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play / pause (reflects live player state)
              StreamBuilder<PlayerState>(
                stream: RadioPlayerService.instance.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final processing = state?.processingState;
                  final isLoading = processing == ProcessingState.loading ||
                      processing == ProcessingState.buffering;
                  final isPlaying = state?.playing ?? false;

                  if (isLoading) {
                    return const SizedBox(
                      width: 44,
                      height: 44,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    );
                  }

                  return IconButton(
                    onPressed: () => RadioPlayerService.instance.toggle(),
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  );
                },
              ),
              // Close / stop
              IconButton(
                onPressed: () => RadioPlayerService.instance.stop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget get _fallbackArt => Container(
        color: Colors.white24,
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
      );
}
