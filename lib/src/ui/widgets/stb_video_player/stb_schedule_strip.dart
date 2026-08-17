import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/core/services/stb_clock.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Card width + gap. Fixed rather than derived from the viewport so the scroll
/// maths below (`_offsetFor`) stays exact — a 10-foot strip that lands a card
/// half-off the edge reads as broken.
const double _kCardWidth = 240;
const double _kCardGap = 14;
const double _kStripHeight = 176;

/// Thumbnail band at the top of each card. A fixed height (rather than a 16:9
/// AspectRatio) keeps every card identical whatever the source image is, and
/// keeps the strip short enough to stay an overlay rather than a screen.
const double _kThumbHeight = 96;

/// Card corner + border. Kept as constants because the still is clipped to
/// `_kCardRadius - _kCardBorder` — the border's inner edge — and the two must
/// stay in step or the image creeps over the corner again.
const double _kCardRadius = 12;
const double _kCardBorder = 2;

/// Inset on the *list's contents*, not on the list itself.
///
/// The rail spans the full screen width so a partly-scrolled card is clipped by
/// the screen edge. Putting this inset on the enclosing container instead would
/// clip it 24px early, leaving a dead band that reads as padding around the
/// list. Only the first and last cards are held off the edge by it.
const double _kListInset = 24;

/// How the schedule panel is fed by [StbVideoPlayer].
enum ScheduleStatus { loading, ready, empty, error }

/// Parses an EPG timestamp into device-local time. Returns null for anything
/// missing or malformed — the feed is not guaranteed to be clean.
DateTime? parseScheduleTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return DateTime.parse(iso).toLocal();
  } catch (_) {
    return null;
  }
}

/// Index of the program covering [now], or -1 if none does.
///
/// -1 is a normal result, not an error: the feed has real holes in it (22 gaps
/// across one day's window on 2026-07-30, the largest 71 minutes), so "nothing
/// is airing" happens routinely. Callers that need a cursor position should use
/// [scheduleFocusIndex] instead.
int scheduleNowIndex(List<LiveModel> programs, DateTime now) {
  for (var i = 0; i < programs.length; i++) {
    final start = parseScheduleTime(programs[i].startsAt);
    final end = parseScheduleTime(programs[i].endsAt);
    if (start == null || end == null) continue;
    if (!now.isBefore(start) && now.isBefore(end)) return i;
  }
  return -1;
}

/// Where the strip's cursor should land when it opens: whatever is airing now,
/// else the next program to start, else — for a window entirely in the past —
/// the last one. Never index 0 by default, which on a rolling 24h feed would
/// park the viewer most of a day behind.
int scheduleFocusIndex(List<LiveModel> programs, DateTime now) {
  if (programs.isEmpty) return 0;
  final airing = scheduleNowIndex(programs, now);
  if (airing >= 0) return airing;
  final upcoming = programs.indexWhere((p) {
    final start = parseScheduleTime(p.startsAt);
    return start != null && start.isAfter(now);
  });
  return upcoming >= 0 ? upcoming : programs.length - 1;
}

/// Drops programs that have already finished, keeping what is on now and
/// everything still to come.
///
/// The feed returns a rolling window that reaches back over the past day, so
/// without this the strip opens on hours of listings that already aired — the
/// viewer scrolls left into yesterday evening. A now-playing strip should
/// answer "what is on and what is next".
///
/// A program is kept when its end is still ahead, which naturally keeps the one
/// currently airing. Entries whose end time will not parse are kept too: the
/// feed is not clean, and silently hiding a program because we could not read
/// its timestamp is worse than showing it in the wrong place.
///
/// **Returns the list unchanged when the filter would empty it.** These boxes
/// boot with a wrong clock — one in the field came up believing it was 7
/// December and only corrected to 11 August once NTP ran — and a clock that is
/// ahead makes every program look finished. Degrading to the old behaviour
/// beats showing a blank strip on a box whose only fault is that it has not
/// reached an NTP server yet.
List<LiveModel> scheduleFromNow(List<LiveModel> programs, DateTime now) {
  final upcoming = programs.where((p) {
    final end = parseScheduleTime(p.endsAt);
    return end == null || end.isAfter(now);
  }).toList();
  return upcoming.isEmpty ? programs : upcoming;
}

/// Chronological order. The `seasons` map gives no ordering guarantee, and the
/// strip reads left-to-right as time moving forward.
List<LiveModel> sortedByStart(List<LiveModel> programs) {
  return programs.toList()
    ..sort((a, b) {
      final sa = parseScheduleTime(a.startsAt);
      final sb = parseScheduleTime(b.startsAt);
      if (sa == null || sb == null) return 0;
      return sa.compareTo(sb);
    });
}

/// Now-playing EPG strip that slides over the lower third of the STB player.
///
/// **Info-only by design.** The backend's `seasons` payload gives every program
/// the *channel's* live URL and leaves `dvr_url` null, so there is no per-program
/// stream to start — selecting a row could only restart the same live feed. The
/// strip therefore answers "what am I watching / what's next" and nothing more;
/// OK is not wired to playback. If the API ever returns real archive links, make
/// the cards focusable and hand the chosen program to the player.
///
/// Selection is a plain index rather than [FocusNode]s: the player keeps keyboard
/// focus for the whole overlay (see `_onKey` there), so introducing focus nodes
/// here would fight it for D-pad events.
class StbScheduleStrip extends StatefulWidget {
  const StbScheduleStrip({
    super.key,
    required this.visible,
    required this.status,
    required this.programs,
    required this.selectedIndex,
    required this.nowIndex,
    required this.onRetry,
  });

  final bool visible;
  final ScheduleStatus status;
  final List<LiveModel> programs;

  /// Cursor position driven by ←/→ on the remote.
  final int selectedIndex;

  /// Index of the program airing right now, or -1 when none matches.
  final int nowIndex;

  final VoidCallback onRetry;

  /// Scroll offset that centres [index] in a viewport [viewportWidth] wide.
  /// Accounts for [_kListInset], which is part of the scrollable content.
  static double offsetFor(int index, double viewportWidth, int itemCount) {
    const stride = _kCardWidth + _kCardGap;
    final contentWidth = _kListInset * 2 + itemCount * stride - _kCardGap;
    final maxOffset =
        (contentWidth - viewportWidth).clamp(0.0, double.infinity);
    final centred =
        _kListInset + index * stride - (viewportWidth - _kCardWidth) / 2;
    return centred.clamp(0.0, maxOffset);
  }

  @override
  State<StbScheduleStrip> createState() => _StbScheduleStripState();
}

class _StbScheduleStripState extends State<StbScheduleStrip> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant StbScheduleStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opening the panel, or moving the cursor, re-centres the selected card.
    final becameVisible = widget.visible && !oldWidget.visible;
    if (becameVisible || widget.selectedIndex != oldWidget.selectedIndex) {
      _centreOnSelection(animate: !becameVisible);
    }
  }

  void _centreOnSelection({required bool animate}) {
    if (widget.programs.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = StbScheduleStrip.offsetFor(
        widget.selectedIndex,
        _scroll.position.viewportDimension,
        widget.programs.length,
      );
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    return AnimatedSlide(
      offset: widget.visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: Container(
            // No horizontal padding here — see [_kListInset].
            padding: const EdgeInsets.only(top: 12, bottom: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xF20E0F13),
                  Color(0xCC0E0F13),
                  Colors.transparent
                ],
                stops: [0, 0.62, 1],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _kListInset),
                  child: Row(
                    children: [
                      TvSectionHeader(l.sectionSchedule),
                      const Spacer(),
                      if (widget.status == ScheduleStatus.ready)
                        _CursorHint(
                          position: widget.selectedIndex + 1,
                          total: widget.programs.length,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(height: _kStripHeight, child: _body(l)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l) {
    switch (widget.status) {
      case ScheduleStatus.loading:
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: kTvAccent, strokeWidth: 3),
          ),
        );
      case ScheduleStatus.empty:
        return _Message(text: l.noSchedule);
      case ScheduleStatus.error:
        return _Message(
            text: l.scheduleLoadError,
            onRetry: widget.onRetry,
            retryLabel: l.retry);
      case ScheduleStatus.ready:
        return ListView.separated(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // driven by the remote
          padding: const EdgeInsets.symmetric(horizontal: _kListInset),
          itemCount: widget.programs.length,
          separatorBuilder: (_, __) => const SizedBox(width: _kCardGap),
          itemBuilder: (context, i) => _ProgramCard(
            program: widget.programs[i],
            selected: i == widget.selectedIndex,
            isNow: i == widget.nowIndex,
            nowLabel: l.badgeNow,
          ),
        );
    }
  }
}

// ─── Program card ─────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.selected,
    required this.isNow,
    required this.nowLabel,
  });

  final LiveModel program;
  final bool selected;
  final bool isNow;
  final String nowLabel;

  static String _time(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      // Through StbClock, not toLocal(): the box's system zone is wrong on any
      // box where `su` is refused, and nothing in the app can fix it there.
      return DateFormat('HH:mm')
          .format(StbClock.instance.toBoxLocal(DateTime.parse(iso)));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _time(program.startsAt);
    final end = _time(program.endsAt);
    final range = end.isEmpty ? start : '$start – $end';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: _kCardWidth,
      // No padding on the card itself, so the still runs edge to edge; only the
      // text below is inset.
      //
      // Deliberately NOT `clipBehavior` here: a Container clips to the *outer*
      // rounded rect, while its border is drawn inside that rect, so the still's
      // top corners creep over the border. The ClipRRect below clips to the
      // inner radius instead.
      decoration: BoxDecoration(
        color: selected ? kTvAccent.withValues(alpha: 0.22) : kTvSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          width: _kCardBorder,
          color: selected ? kTvAccent : Colors.white12,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: kTvAccent.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      // The Container already insets its child by the border width, so clipping
      // to `radius - border` lands exactly on the border's inner edge — no
      // sliver of image showing through the corner curve.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius - _kCardBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _kThumbHeight,
              width: double.infinity,
              child: _Thumb(url: program.images.getThumbnail()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 6, 9, 0),
              child: Row(
                children: [
                  Text(
                    range,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : kTvAccent,
                    ),
                  ),
                  const Spacer(),
                  if (isNow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kTvAccent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        nowLabel,
                        style: GoogleFonts.sora(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 3, 9, 8),
                child: Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : Colors.white70,
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

// ─── Program thumbnail ────────────────────────────────────────────────────────

/// Program still from the EPG feed.
///
/// Plain [Image.network], matching the rest of the app (`cached_network_image`
/// is a dependency but is only used in commented-out code). The strip's
/// [ListView] is lazy, so a 90-program day only ever fetches the few cards
/// around the cursor — it does not pull 90 images while the stream is playing.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    // `getThumbnail()` falls back to a placeholder URL when the item has no
    // artwork; showing our own icon beats a remote round-trip for a stock image.
    if (url.isEmpty || url == defaultPosterImage) return const _ThumbFallback();

    return Image.network(
      url,
      fit: BoxFit.cover,
      // Hold the fallback until the first frame decodes, so cards never flash
      // an empty box while scrolling.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const _ThumbFallback();
      },
      errorBuilder: (_, __, ___) => const _ThumbFallback(),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      alignment: Alignment.center,
      child: const Icon(Icons.live_tv_rounded, color: Colors.white24, size: 26),
    );
  }
}

// ─── Header cursor hint ("12 / 94") ───────────────────────────────────────────

class _CursorHint extends StatelessWidget {
  const _CursorHint({required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$position / $total',
      style: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
      ),
    );
  }
}

// ─── Loading / empty / error message ──────────────────────────────────────────

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry, this.retryLabel});

  final String text;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: GoogleFonts.sora(fontSize: 14, color: Colors.white54),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryLabel ?? '',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTvAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
