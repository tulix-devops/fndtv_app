import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/widgets/black_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';

class VodFullScreen extends StatefulWidget {
  const VodFullScreen({
    super.key,
    required this.controller,
    required this.updateVideoController,
    required this.contentType,
    required this.video,
  });

  final VideoPlayerController controller;
  final void Function(String link) updateVideoController;
  final ContentType contentType;
  final LiveModel video;

  @override
  State<VodFullScreen> createState() => _VodFullScreenState();
}

class _VodFullScreenState extends State<VodFullScreen> {
  late final FocusNode playPauseFocus;
  late final FocusNode arrowBackFocus;

  /// Focus target for the schedule sheet itself — holds focus while the list
  /// loads (so the Back key routes to it) before the first card autofocuses.
  late final FocusNode _scheduleFocus;

  ({int selectedPage, int selectedItemIndex})? selectedLinkIndexes;

  bool isSeasonsOpen = false;

  // ── Schedule state ───────────────────────────────────────────────────────
  // Only today's schedule is shown, so the date is fixed to now.
  final DateTime _selectedDate = DateTime.now();
  List<LiveModel> _programs = [];
  bool _dvrLoading = false;
  bool _dvrError = false;

  void _openDvr() {
    setState(() {
      isSeasonsOpen = true;
      _dvrLoading = true;
      _dvrError = false;
      _programs = [];
    });
    context.read<VideoPlayerCubit>().handleVisibility(forceVisible: true);
    _fetchDvr();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleFocus.requestFocus();
    });
  }

  void _closeDvr() {
    setState(() => isSeasonsOpen = false);
    context.read<VideoPlayerCubit>().handleVisibility();
    playPauseFocus.requestFocus();
  }

  Future<void> _fetchDvr() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final res = await context.read<ContentRepository>().getContentDetail(
            contentType: widget.video.typeId,
            id: widget.video.id,
            date: dateStr,
          );
      final LiveModel? data = switch (res) {
        SuccessModel<LiveModel>() => res.data,
        PaginatedModel<LiveModel>() => res.data,
        _ => null,
      };
      if (!mounted) return;
      setState(() {
        _programs = data?.scheduleItems ?? [];
        _dvrLoading = false;
        _dvrError = data == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dvrError = true;
        _dvrLoading = false;
      });
    }
  }

  @override
  void initState() {
    _scheduleFocus = FocusNode();
    playPauseFocus = FocusNode(
      onKeyEvent: (node, event) {
        bool isInitialized = widget.controller.value.isInitialized;
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final Duration currentPosition = widget.controller.value.position;
          final cubit = context.read<VideoPlayerCubit>();
          final bool wasVisible = cubit.state.isVisible;

          // Down first reveals the controls (and the schedule hint). Only once
          // the controls are already showing does another Down open the
          // schedule sheet — so the first press never jumps straight into it.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (!wasVisible) {
              cubit.handleVisibility(forceVisible: true);
            } else if (widget.contentType == ContentType.television &&
                !isSeasonsOpen) {
              _openDvr();
            }
            return KeyEventResult.handled;
          }

          cubit.handleVisibility();

          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.mediaRewind &&
                  isInitialized) {
            widget.controller.seekTo(
              currentPosition - const Duration(seconds: 30),
            );
            return KeyEventResult.handled;
          }
          if ((event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.mediaFastForward) &&
              isInitialized) {
            widget.controller.seekTo(
              currentPosition + const Duration(seconds: 30),
            );
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.goBack) {
            arrowBackFocus.requestFocus();
            return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
    );
    arrowBackFocus = FocusNode(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (isSeasonsOpen) {
          if (event.logicalKey == LogicalKeyboardKey.goBack) {
            _closeDvr();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        context.read<VideoPlayerCubit>().handleVisibility();
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          playPauseFocus.requestFocus();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          context.pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.skipRemainingHandlers;
      },
    );
    playPauseFocus.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    _scheduleFocus.dispose();
    arrowBackFocus.dispose();
    playPauseFocus.dispose();
    super.dispose();
  }

  String _playIcon() {
    return widget.controller.value.isPlaying
        ? Assets.videoPause
        : Assets.videoPlay;
  }

  void _togglePlayPause(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    isPlaying ? widget.controller.pause() : widget.controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoPlayerCubit, VideoPlayerState>(
      listenWhen: (previous, current) =>
          previous.isVisible != current.isVisible,
      listener: (context, state) {
        if (!isSeasonsOpen) playPauseFocus.requestFocus();
      },
      builder: (context, state) {
        // The schedule (DVR archive) only applies to live TV — not radio or VOD.
        final isLiveTv = widget.contentType == ContentType.television;
        // On-demand (VOD) content has a fixed duration, so it gets a scrub bar.
        final isVod = widget.contentType == ContentType.dvr;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Keep the video undimmed while the schedule sheet is open so the
            // layout behind it stays readable.
            if (state.isVisible && !isSeasonsOpen) const BlackBackground(),
            if (!isSeasonsOpen) ...[
              Positioned(
                left: 60,
                top: 20,
                child: VideoButton(
                  onPressed: (ctx) => context.pop(),
                  icon: Assets.arrowLeft,
                  focusNode: arrowBackFocus,
                ),
              ),
              Positioned(
                left: 60,
                right: 10,
                bottom: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    VideoButton(
                      onPressed: (context) {
                        _togglePlayPause(context);
                        context.read<VideoPlayerCubit>().handleVisibility();
                      },
                      icon: _playIcon(),
                      focusNode: playPauseFocus,
                    ),
                  ],
                ),
              ),
              // Bottom hint that a schedule is available — press Down to open.
              // Live TV only (radio and VOD have no schedule).
              if (isLiveTv && state.isVisible)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: IgnorePointer(child: _ScheduleHint()),
                ),
              // VOD progress / scrub bar — rewind & fast-forward with ◀ / ▶.
              if (isVod && state.isVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: getVodSeekbar(context),
                ),
            ],
            if (isSeasonsOpen) _buildScheduleSheet(context),
          ],
        );
      },
    );
  }

  /// Bottom sheet listing today's schedule as a horizontal strip of picture
  /// cards. The video stays visible above it.
  Widget _buildScheduleSheet(BuildContext context) {
    final colors = context.uiKitColors;
    final sheetHeight = MediaQuery.of(context).size.height * 0.5;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Focus(
        focusNode: _scheduleFocus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.goBack) {
            _closeDvr();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.94),
                ],
                stops: const [0, 0.28, 1],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 8, 40, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: Color(0xFFA83734), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          "Today's Schedule",
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70, size: 28),
                          onPressed: _closeDvr,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 200, child: _buildScheduleList(colors)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList(UiKitColors colors) {
    if (_dvrLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA83734)),
      );
    }
    if (_dvrError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 34),
            const SizedBox(height: 8),
            Text('Could not load schedule',
                style: GoogleFonts.sora(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _dvrLoading = true;
                  _dvrError = false;
                });
                _fetchDvr();
              },
              child: Text('Retry', style: TextStyle(color: colors.accent)),
            ),
          ],
        ),
      );
    }
    if (_programs.isEmpty) {
      return Center(
        child: Text('No programs today',
            style: GoogleFonts.sora(color: Colors.white38, fontSize: 14)),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(48, 6, 48, 18),
      itemCount: _programs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, i) {
        final program = _programs[i];
        return SizedBox(
          width: 240,
          child: Align(
            alignment: Alignment.topLeft,
            child: _DvrProgramCard(
              program: program,
              autofocus: i == 0,
              onTap: () {
                final link = program.sources.getPreferredVideoSource() ?? '';
                if (link.isNotEmpty) {
                  widget.updateVideoController(link);
                }
                _closeDvr();
              },
            ),
          ),
        );
      },
    );
  }

  Widget getVodSeekbar(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final String duration = value.duration.formatDuration();
        final String position = value.position.formatDuration();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(position, style: TextStyles.bodyMediumBold.surface(context)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: VideoSeekbar(
                    controller: widget.controller,
                    updateController: widget.updateVideoController,
                  ),
                ),
              ),
              Text(duration, style: TextStyles.bodyMediumBold.surface(context)),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULE HINT  (bottom "press down" affordance)
// ═══════════════════════════════════════════════════════════════════════════

/// A subtle non-interactive hint centered at the bottom of the player: the word
/// "Schedule" over a gently bobbing down-chevron, telling the viewer to press
/// Down to reveal the schedule.
class _ScheduleHint extends StatefulWidget {
  const _ScheduleHint();

  @override
  State<_ScheduleHint> createState() => _ScheduleHintState();
}

class _ScheduleHintState extends State<_ScheduleHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.85);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Schedule',
            style: GoogleFonts.sora(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 1),
          AnimatedBuilder(
            animation: _bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _bob.value * 4),
              child: child,
            ),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: color, size: 26),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DVR PROGRAM ROW
// ═══════════════════════════════════════════════════════════════════════════

String _dvrFmtTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    // Through StbClock, not toLocal() — see StbClock: the system zone stays
    // wrong on a box where `su` is refused.
    return DateFormat('HH:mm')
        .format(StbClock.instance.toBoxLocal(DateTime.parse(iso)));
  } catch (_) {
    return '';
  }
}

class _DvrProgramCard extends StatefulWidget {
  final LiveModel program;
  final VoidCallback onTap;
  final bool autofocus;

  const _DvrProgramCard({
    required this.program,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_DvrProgramCard> createState() => _DvrProgramCardState();
}

class _DvrProgramCardState extends State<_DvrProgramCard> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = _node.hasFocus);
    if (_node.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(context,
              alignment: 0.5, duration: const Duration(milliseconds: 260));
        }
      });
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  bool get _isCurrent {
    final s = widget.program.startsAt, e = widget.program.endsAt;
    if (s == null || s.isEmpty || e == null || e.isEmpty) return false;
    try {
      final now = DateTime.now();
      final st = DateTime.parse(s).toLocal();
      final en = DateTime.parse(e).toLocal();
      return !now.isBefore(st) && now.isBefore(en);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFA83734);
    final start = _dvrFmtTime(widget.program.startsAt);
    final end = _dvrFmtTime(widget.program.endsAt);
    final timeRange = end.isEmpty ? start : '$start – $end';
    final thumb = widget.program.images.getThumbnail();
    final hasThumb = thumb.startsWith('http');
    final isCurrent = _isCurrent;

    return InkWell(
      focusNode: _node,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _focused ? 1.04 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focused
                      ? accent
                      : (isCurrent
                          ? accent.withValues(alpha: 0.6)
                          : Colors.white24),
                  width: _focused ? 3 : 1,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasThumb)
                        Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder,
                        )
                      else
                        _placeholder,
                      // Time badge
                      if (timeRange.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              timeRange,
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      // Live now badge
                      if (isCurrent)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      // Play affordance on focus
                      if (_focused)
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(
                color: _focused ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: _focused ? FontWeight.w700 : FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _placeholder => Container(
        color: const Color(0xFF23252B),
        child: const Icon(Icons.live_tv_rounded, color: Colors.white24, size: 40),
      );
}
