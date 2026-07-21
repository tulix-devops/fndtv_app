import 'dart:math' as math;

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/audio/radio_player_service.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/pages/live_detail/new_live_detail_page.dart';
import 'package:fndtv/src/ui/pages/video_player/video_player_page.dart';
import 'package:ui_kit/ui_kit.dart';

/// Whether the content tabs should show a loading spinner.
bool contentIsLoading(ContentState state) =>
    state.status == Status.initial ||
    state.status == Status.loading ||
    (state.contentList == null && state.status != Status.failure);

/// Centered loading spinner for the content tabs.
class ContentLoading extends StatelessWidget {
  final UiKitColors colors;
  const ContentLoading({super.key, required this.colors});

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(color: colors.accent));
}

/// Centered error state with retry for the content tabs.
class ContentError extends StatelessWidget {
  final UiKitColors colors;
  const ContentError({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 44, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            context.l.channelsLoadError,
            style: GoogleFonts.sora(color: colors.textPrimary, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.read<ContentCubit>().getContentForMultipleTypes([8, 10]),
            child: Text(context.l.retry, style: TextStyle(color: colors.accent)),
          ),
        ],
      ),
    );
  }
}

/// Opens a channel directly in the full-screen player.
void openChannel(BuildContext context, LiveModel video, ContentType type) {
  Navigator.of(context).pushNamed(
    VideoPlayerPage.path,
    arguments: {
      'channel': video,
      'contentCubit': context.read<ContentCubit>(),
      'contentType': type,
    },
  );
}

/// Opens a live channel's detail page (mini-player + DVR/EPG schedule).
void openLiveDetail(BuildContext context, LiveModel channel) {
  Navigator.of(context).pushNamed(
    NewLiveDetailPage.path,
    arguments: {'channel': channel},
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER  (dot + label)
// ═══════════════════════════════════════════════════════════════════════════

class FndtvSectionHeader extends StatelessWidget {
  final String label;

  const FndtvSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary, // white/light title (TV style); dot stays red
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROUNDED PLAY BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class RoundedPlayButton extends StatelessWidget {
  final double size;
  final bool filled;
  final IconData icon;

  const RoundedPlayButton({
    super.key,
    this.size = 52,
    this.filled = false,
    this.icon = Icons.play_arrow_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? colors.accent : colors.accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: colors.accent, width: 2),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: filled ? Colors.white : colors.accent,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS PILL  (LIVE / US TIME / RADIO)
// ═══════════════════════════════════════════════════════════════════════════

class StatusPill extends StatelessWidget {
  final String text;
  final IconData icon;

  const StatusPill({super.key, required this.text, this.icon = Icons.circle});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE POSTER TILE  (channel banner; tap -> detail page)
// ═══════════════════════════════════════════════════════════════════════════

class LivePosterTile extends StatelessWidget {
  final LiveModel channel;
  /// Badge text; when null, falls back to the localized "LIVE" label.
  final String? badge;

  /// Channel banner images are 461x310 (≈3:2).
  static const double _aspect = 461 / 310;

  const LivePosterTile({
    super.key,
    required this.channel,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final imageUrl = channel.images.getBanner();

    return GestureDetector(
      onTap: () => openLiveDetail(context, channel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: _aspect,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.live_tv_rounded, color: colors.textMuted, size: 44),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusPill(text: badge ?? context.l.badgeLive, icon: Icons.circle),
                ),
                const Positioned(
                  bottom: 12,
                  right: 12,
                  child: RoundedPlayButton(size: 48, filled: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RADIO ROW CARD  (gold mic + equalizer; tap -> player)
// ═══════════════════════════════════════════════════════════════════════════

class RadioRowCard extends StatelessWidget {
  final LiveModel channel;

  const RadioRowCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return GestureDetector(
      onTap: () => RadioPlayerService.instance.play(channel),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(width: 0.5, color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE088),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: Color(0xFF7A2A16), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.title,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  EqualizerBars(color: colors.accent, height: 14, bars: 5),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const RoundedPlayButton(size: 44),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED EQUALIZER BARS
// ═══════════════════════════════════════════════════════════════════════════

class EqualizerBars extends StatefulWidget {
  final Color color;
  final double height;
  final int bars;

  const EqualizerBars({
    super.key,
    required this.color,
    this.height = 16,
    this.bars = 5,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.bars, (i) {
            final phase = i / widget.bars;
            final v = 0.3 +
                0.7 *
                    (0.5 +
                        0.5 *
                            math.sin(
                              _controller.value * 2 * math.pi + phase * math.pi * 2,
                            ));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: widget.height * v,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
