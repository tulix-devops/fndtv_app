import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';

/// Dark, 10-foot TV palette. TV screens use a cinematic dark background rather
/// than the light mobile theme.
const Color kTvBg = Color(0xFF0E0F13);
const Color kTvSurface = Color(0xFF191B22);
const Color kTvAccent = Color(0xFFC7443F); // brand red, brightened for dark bg

/// Section header for TV — red accent bar + large white label.
class TvSectionHeader extends StatelessWidget {
  final String label;
  const TvSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 20,
            decoration: BoxDecoration(
              color: kTvAccent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A focusable channel row for TV: a compact poster card on the left and a large
/// title + details block that fills the remaining horizontal space. Owns its
/// focus node and lights up red when focused by the remote.
class TvChannelRow extends StatefulWidget {
  final LiveModel channel;
  final String badge;
  final VoidCallback onTap;
  final bool autofocus;

  const TvChannelRow({
    super.key,
    required this.channel,
    required this.badge,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<TvChannelRow> createState() => _TvChannelRowState();
}

class _TvChannelRowState extends State<TvChannelRow> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.channel.images.getBanner();

    // Sizes derive from the height the parent gives us (via Expanded), so the
    // row fills the available space and everything fits with no scrolling —
    // works at any TV resolution / density.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight.isFinite ? constraints.maxHeight : 140;
        final double maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 600;
        double cardH = (h - 12).clamp(56.0, 240.0);
        double cardW = cardH * (461 / 310);
        // Never let the card take more than ~42% of the row width, so the title
        // stays visible — important on single-item pages (Radio) and when the
        // nav rail pushes the content and narrows the row.
        final double cardWCap = maxW * 0.42;
        if (cardW > cardWCap) {
          cardW = cardWCap;
          cardH = cardW * (310 / 461);
        }
        final double titleSize = (cardH * 0.22).clamp(15.0, 30.0);
        final double gap = (cardW * 0.12).clamp(16.0, 40.0);

        return InkWell(
          focusNode: _node,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _focused ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Poster card — fills the row height, width from aspect ratio.
                SizedBox(
                  width: cardW,
                  height: cardH,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _focused ? kTvAccent : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: _focused
                          ? [
                              BoxShadow(
                                color: kTvAccent.withValues(alpha: 0.45),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            banner,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: kTvSurface,
                              child: const Icon(Icons.live_tv_rounded,
                                  color: Colors.white24, size: 40),
                            ),
                          ),
                          Positioned(
                              bottom: 8, left: 8, child: _badgePill(widget.badge)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                // Title + play affordance fill the remaining width.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: titleSize * 0.5),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: titleSize * 0.7, vertical: titleSize * 0.35),
                        decoration: BoxDecoration(
                          color: _focused ? kTvAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _focused ? kTvAccent : Colors.white24,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: _focused ? Colors.white : Colors.white70,
                                size: titleSize),
                            SizedBox(width: titleSize * 0.25),
                            Text(
                              widget.badge,
                              style: GoogleFonts.sora(
                                fontSize: titleSize * 0.55,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: _focused ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badgePill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: kTvAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, color: Colors.white, size: 6),
            const SizedBox(width: 5),
            Text(
              text,
              style: GoogleFonts.sora(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}
