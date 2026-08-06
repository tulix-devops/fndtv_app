import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';

/// Live channel detail — inline mini-player at the top, with the channel's DVR /
/// EPG schedule (`seasons`) listed below, one full-width item per row.
class NewLiveDetailPage extends StatefulWidget {
  final LiveModel channel;

  const NewLiveDetailPage({super.key, required this.channel});

  static const path = 'live-detail';
  static const name = 'live-detail';

  @override
  State<NewLiveDetailPage> createState() => _NewLiveDetailPageState();
}

class _NewLiveDetailPageState extends State<NewLiveDetailPage> {
  bool _loading = true;
  bool _error = false;
  bool _isGrid = false;
  // Fixed at page open: the schedule always covers the current day (the
  // backend ignores the date parameter), so nothing can change this.
  final DateTime _selectedDate = DateTime.now();
  List<LiveModel> _programs = const [];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await context.read<ContentRepository>().getContentDetail(
            contentType: widget.channel.typeId,
            id: widget.channel.id,
            date: dateStr,
          );
      final LiveModel? data = switch (res) {
        SuccessModel<LiveModel>() => res.data,
        PaginatedModel<LiveModel>() => res.data,
        _ => null,
      };
      if (!mounted) return;
      setState(() {
        if (data != null) {
          _programs = data.scheduleItems;
          _loading = false;
        } else {
          _error = true;
          _loading = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final link = widget.channel.sources.getPreferredVideoSource() ?? '';

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branded app bar — back + page name (left), crest logo (right)
          Container(
            color: const Color(0xFFA83734),
            padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 8, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l.badgeLive,
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        widget.channel.title,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/img/main_logo_transparent.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // Scrollable content below the app bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Inline mini-player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _InlineLivePlayer(url: link),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule controls: title + grid/list toggle + date chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    context.l.archive,
                    style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                  const Spacer(),
                  _ViewToggle(
                    isGrid: _isGrid,
                    onChanged: (v) => setState(() => _isGrid = v),
                    colors: colors,
                  ),
                  const SizedBox(width: 10),
                  _DateChip(date: _selectedDate, colors: colors),
                ],
              ),
            ),
            const SizedBox(height: 12),

                // DVR / EPG body (grid or list)
                Expanded(child: _buildScheduleBody(colors)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleBody(UiKitColors colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(context.l.scheduleLoadError,
                style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = false;
                });
                _fetchSchedule();
              },
              child: Text(context.l.retry, style: TextStyle(color: colors.accent)),
            ),
          ],
        ),
      );
    }
    if (_programs.isEmpty) {
      return Center(
        child: Text(context.l.noSchedule,
            style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14)),
      );
    }

    final now = DateTime.now();
    bool isCurrent(LiveModel p) => _isAiringNow(p, now);

    if (_isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // Sized to thumbnail + time + three title lines. At 0.82 the cards
          // were tall enough for five, so every one ended in a block of empty
          // space.
          childAspectRatio: 0.95,
        ),
        itemCount: _programs.length,
        itemBuilder: (context, i) =>
            _DvrGridCard(program: _programs[i], isCurrent: isCurrent(_programs[i])),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _DvrRow(program: _programs[i], isCurrent: isCurrent(_programs[i])),
    );
  }

  static bool _isAiringNow(LiveModel p, DateTime now) {
    final s = p.startsAt, e = p.endsAt;
    if (s == null || s.isEmpty || e == null || e.isEmpty) return false;
    try {
      final start = DateTime.parse(s).toLocal();
      final end = DateTime.parse(e).toLocal();
      return !now.isBefore(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW TOGGLE (grid / list)
// ═══════════════════════════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;
  final UiKitColors colors;

  const _ViewToggle({required this.isGrid, required this.onChanged, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(Icons.grid_view_rounded, isGrid, () => onChanged(true), true),
          _seg(Icons.view_list_rounded, !isGrid, () => onChanged(false), false),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, bool active, VoidCallback onTap, bool left) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? colors.accent : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: left ? const Radius.circular(9) : Radius.zero,
            right: left ? Radius.zero : const Radius.circular(9),
          ),
        ),
        child: Icon(icon, size: 18, color: active ? Colors.white : colors.accent),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATE CHIP
// ═══════════════════════════════════════════════════════════════════════════

/// Shows which day the schedule covers. Deliberately not tappable: the backend
/// ignores the date parameter and always returns the current Paris calendar
/// day, so a picker could only ever re-fetch the same list.
class _DateChip extends StatelessWidget {
  final DateTime date;
  final UiKitColors colors;

  const _DateChip({required this.date, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('MMM d').format(date),
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.calendar_today_rounded, size: 14, color: colors.accent),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INLINE MINI PLAYER (self-contained video_player + chewie)
// ═══════════════════════════════════════════════════════════════════════════

class _InlineLivePlayer extends StatefulWidget {
  final String url;

  const _InlineLivePlayer({required this.url});

  @override
  State<_InlineLivePlayer> createState() => _InlineLivePlayerState();
}

class _InlineLivePlayerState extends State<_InlineLivePlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        formatHint: VideoFormat.hls,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          // This page only ever plays the channel's live source, so there is
          // nothing to scrub. Without this chewie draws a progress bar, a
          // position/duration readout and ±10s buttons over the HLS live
          // window, which reported nonsense like "00:04 / 00:12".
          isLive: true,
          // Chewie's own live layout is `[Expanded(LIVE)] [mute] [Spacer]
          // [fullscreen]`, which splits the free space in two and leaves mute
          // floating in the middle of the bar with the options button off on
          // its own edge — placement by accident. See [_LiveControls].
          //
          // Passed as `overlay` rather than `customControls` deliberately: in
          // fullscreen chewie wraps customControls in SafeArea, so a landscape
          // display cutout insets the layer and everything centred in it lands
          // off-centre by half the inset. `overlay` sits in the same Stack with
          // no SafeArea, so it spans the true player bounds.
          showControls: false,
          overlay: const Positioned.fill(child: _LiveControls()),
          // Explicit, because the default infers rotation from
          // `videoPlayerController.value.size` — and if the stream has not
          // reported its dimensions yet both are 0, which falls through to the
          // "square video" branch and does not rotate at all.
          deviceOrientationsOnEnterFullScreen: const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          deviceOrientationsAfterFullScreen: const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          aspectRatio: 16 / 9,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFFA83734),
            handleColor: const Color(0xFFA83734),
            backgroundColor: Colors.grey,
            bufferedColor: Colors.white24,
          ),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: _failed
            ? const Center(
                child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
              )
            : (_chewie != null
                ? Chewie(controller: _chewie!)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE PLAYER CONTROLS
// ═══════════════════════════════════════════════════════════════════════════

/// Controls for a live-only player: three anchors, nothing floating.
///
///   ● LIVE ─ top-left        play/pause ─ dead centre        mute + full ─
///                                                            bottom-right
///
/// Replaces chewie's material controls, which spread a live stream's four
/// elements across the bar with no relationship between them. Building our own
/// also means the badge is localized — chewie hardcodes the English "LIVE".
class _LiveControls extends StatefulWidget {
  const _LiveControls();

  @override
  State<_LiveControls> createState() => _LiveControlsState();
}

class _LiveControlsState extends State<_LiveControls> {
  static const _fade = Duration(milliseconds: 250);
  static const _autoHideAfter = Duration(seconds: 3);

  bool _visible = true;
  Timer? _hideTimer;
  ChewieController? _chewie;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captured here rather than read inside the timer callback:
    // ChewieController.of registers an inherited-widget dependency, which
    // belongs in build/didChangeDependencies, not in an async callback.
    _chewie = ChewieController.of(context);
    _restartHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  /// Only auto-hides while playing — controls left up over a paused frame are
  /// what the viewer is reaching for.
  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideAfter, () {
      if (mounted && (_chewie?.isPlaying ?? false)) {
        setState(() => _visible = false);
      }
    });
  }

  void _toggleVisible() {
    setState(() => _visible = !_visible);
    if (_visible) _restartHideTimer();
  }

  /// Pressing a control also re-arms the timer, so the bar doesn't vanish
  /// mid-interaction.
  void _act(VoidCallback action) {
    action();
    setState(_restartHideTimer);
  }

  @override
  Widget build(BuildContext context) {
    final chewie = ChewieController.of(context);
    final controller = chewie.videoPlayerController;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sized from the player, so it is proportionate inline and fullscreen
        // rather than a fixed size that only suits one of them.
        final buttonSize = (constraints.maxWidth * 0.16).clamp(48.0, 72.0);

        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final muted = value.volume == 0;

            // Corner controls keep clear of a display cutout, but only in
            // fullscreen: inline, nothing above has consumed the status-bar
            // padding yet, so a SafeArea here would shove the badge down into
            // the middle of a player that sits well below the status bar.
            Widget corners = Stack(
              children: [
                const Positioned(top: 10, left: 12, child: _LiveBadge()),
                // Mute and fullscreen are both player chrome, so they sit
                // together in one corner rather than at opposite ends.
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconButton(
                        icon: muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onPressed: () =>
                            _act(() => chewie.setVolume(muted ? 1 : 0)),
                      ),
                      _IconButton(
                        icon: chewie.isFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        onPressed: () => _act(chewie.toggleFullScreen),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (chewie.isFullScreen) corners = SafeArea(child: corners);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Tap-anywhere catcher, underneath everything so it only
                // receives taps that miss an actual button.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleVisible,
                ),

                IgnorePointer(
                  ignoring: !_visible,
                  child: AnimatedOpacity(
                    opacity: _visible ? 1 : 0,
                    duration: _fade,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // No full-surface scrim: over a player this small it
                        // reads as a murky wash across the picture. Each
                        // control carries its own backing instead.
                        Center(
                          child: _CenterButton(
                            size: buttonSize,
                            isBuffering: value.isBuffering,
                            isPlaying: value.isPlaying,
                            onPressed: () => _act(chewie.togglePause),
                          ),
                        ),
                        corners,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Same shape as the channel tiles' status pill, but localized and sized for
/// an overlay.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.uiKitColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            context.l.badgeLive,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final double size;
  final bool isBuffering;
  final bool isPlaying;
  final VoidCallback onPressed;

  const _CenterButton({
    required this.size,
    required this.isBuffering,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isBuffering) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        // Its own disc, now that there is no scrim to keep the icon legible
        // against a bright frame.
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DVR / SCHEDULE ROW  (full-width, one per row)
// ═══════════════════════════════════════════════════════════════════════════

String _fmtTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return '';
  }
}

class _DvrRow extends StatelessWidget {
  final LiveModel program;
  final bool isCurrent;

  const _DvrRow({required this.program, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final thumb = program.images.getThumbnail();
    final hasThumb = thumb.isNotEmpty && thumb != defaultPosterImage;
    final start = _fmtTime(program.startsAt);
    final end = _fmtTime(program.endsAt);

    final titleColor = isCurrent ? Colors.white : colors.textPrimary;
    final timeColor = isCurrent ? Colors.white : colors.accent;
    final range = end.isEmpty ? start : '$start – $end';

    return Container(
      height: 78,
      padding: const EdgeInsets.all(10),
      decoration: _scheduleCardDecoration(colors, isCurrent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgramThumb(
            url: thumb,
            hasThumb: hasThumb,
            width: 104,
            height: 58,
            radius: 9,
            iconSize: 22,
            colors: colors,
          ),
          const SizedBox(width: 12),
          // Time above the title rather than in a right-hand column: every row's
          // time then starts at the same x (still scannable), and the title gets
          // the whole remaining width instead of ~100px, which is what was
          // truncating it to "Trip Around the World...".
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (range.isNotEmpty)
                  Text(
                    range,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: timeColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                const SizedBox(height: 4),
                // Flexible, not a bare Text: the row height is fixed so the list
                // scans evenly, and at a large system font scale two lines no
                // longer fit — this drops to one and ellipsizes instead of
                // overflowing.
                Flexible(
                  child: Text(
                    program.title,
                    style: GoogleFonts.sora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: titleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED SCHEDULE CARD PIECES
// ═══════════════════════════════════════════════════════════════════════════

/// Same recipe as every other card in the app (About, radio rows, guide chips):
/// a neutral surface on the dark page plus a hairline border. The schedule used
/// to be the one place with a light-pink fill, which is what made it stick out.
BoxDecoration _scheduleCardDecoration(UiKitColors colors, bool isCurrent) {
  return BoxDecoration(
    color: isCurrent ? colors.accent : colors.bgCard,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      width: isCurrent ? 1 : 0.5,
      color: isCurrent ? colors.accent : colors.border,
    ),
  );
}

class _ProgramThumb extends StatelessWidget {
  final String url;
  final bool hasThumb;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;
  final UiKitColors colors;

  const _ProgramThumb({
    required this.url,
    required this.hasThumb,
    required this.radius,
    required this.iconSize,
    required this.colors,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // bgPrimary, not bgSurface: the card itself is bgCard, and bgSurface is the
    // same value — the placeholder would be invisible against it.
    Widget fallback() => Container(
          color: colors.bgPrimary,
          child: Icon(Icons.live_tv_rounded, color: colors.textMuted, size: iconSize),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: hasThumb
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              )
            : fallback(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DVR / SCHEDULE GRID CARD
// ═══════════════════════════════════════════════════════════════════════════

class _DvrGridCard extends StatelessWidget {
  final LiveModel program;
  final bool isCurrent;

  const _DvrGridCard({required this.program, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final thumb = program.images.getThumbnail();
    final hasThumb = thumb.isNotEmpty && thumb != defaultPosterImage;
    final start = _fmtTime(program.startsAt);
    final end = _fmtTime(program.endsAt);
    final range = end.isEmpty ? start : '$start – $end';

    final titleColor = isCurrent ? Colors.white : colors.textPrimary;
    final timeColor = isCurrent ? Colors.white : colors.accent;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _scheduleCardDecoration(colors, isCurrent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _ProgramThumb(
              url: thumb,
              hasThumb: hasThumb,
              radius: 10,
              iconSize: 26,
              colors: colors,
            ),
          ),
          const SizedBox(height: 8),
          if (range.isNotEmpty)
            Text(
              range,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: timeColor,
                letterSpacing: 0.2,
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              program.title,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: titleColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
