import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';

/// Persistent "now playing" backdrop for radio (audio-only) playback: a centered
/// radio indicator with the station name and the artwork in the top-right
/// corner. Rendered underneath the player controls so it stays visible even
/// when the controls auto-hide.
class RadioNowPlaying extends StatelessWidget {
  final LiveModel video;

  const RadioNowPlaying({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFA83734);
    final art = video.images.getThumbnail();
    final hasArt = art.startsWith('http');

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0E0F13),
        child: Stack(
          children: [
            // Center radio indicator
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                    child: const Icon(Icons.radio_rounded,
                        color: Colors.white, size: 62),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    video.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.white, size: 8),
                        const SizedBox(width: 7),
                        Text(
                          'ON AIR',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Small artwork indicator in the top-right corner
            if (hasArt)
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      width: 150,
                      height: 86,
                      child: Image.network(art,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
