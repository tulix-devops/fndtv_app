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
  late final FocusNode _archiveBtnFocus;

  ({int selectedPage, int selectedItemIndex})? selectedLinkIndexes;

  bool isSeasonsOpen = false;

  // ── DVR state ──────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  List<LiveModel> _programs = [];
  bool _dvrLoading = false;
  bool _dvrError = false;

  List<DateTime> get _dvrDates {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return List.generate(8, (i) => today.subtract(Duration(days: 7 - i)));
  }

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
      if (mounted) arrowBackFocus.requestFocus();
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
    _archiveBtnFocus = FocusNode();
    playPauseFocus = FocusNode(
      onKeyEvent: (node, event) {
        bool isInitialized = widget.controller.value.isInitialized;
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final Duration currentPosition = widget.controller.value.position;
          context.read<VideoPlayerCubit>().handleVisibility();

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
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _archiveBtnFocus.requestFocus();
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
    _archiveBtnFocus.dispose();
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
        return Stack(
          alignment: Alignment.center,
          children: [
            if (state.isVisible) const BlackBackground(),
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
                right: 20,
                top: 20,
                child: _ArchiveButton(
                  onTap: _openDvr,
                  focusNode: _archiveBtnFocus,
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
            ],
            if (isSeasonsOpen) _buildDvrOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildDvrOverlay(BuildContext context) {
    final colors = context.uiKitColors;
    return Positioned.fill(
      child: FocusScope(
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
          child: Row(
            children: [
              // Left tap-to-close area
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: _closeDvr,
                  child: Container(color: Colors.black.withValues(alpha: 0.55)),
                ),
              ),
              // Right panel
              Expanded(
                flex: 6,
                child: Container(
                  color: const Color(0xFF1A1A1A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                        child: Row(
                          children: [
                            const Icon(Icons.video_library_rounded,
                                color: Color(0xFFA83734), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Archive',
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              focusNode: arrowBackFocus,
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white70),
                              onPressed: _closeDvr,
                            ),
                          ],
                        ),
                      ),
                      // Date chips
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _dvrDates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final date = _dvrDates[i];
                            final isSelected = _isSameDay(date, _selectedDate);
                            return _DvrDateChip(
                              date: date,
                              isSelected: isSelected,
                              onTap: () {
                                if (!isSelected) {
                                  setState(() {
                                    _selectedDate = date;
                                    _dvrLoading = true;
                                    _dvrError = false;
                                    _programs = [];
                                  });
                                  _fetchDvr();
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white12, height: 1),
                      // Program list
                      Expanded(child: _buildDvrProgramList(colors)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDvrProgramList(UiKitColors colors) {
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
            const Icon(Icons.error_outline, color: Colors.white38, size: 36),
            const SizedBox(height: 10),
            Text('Could not load programs',
                style: GoogleFonts.sora(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
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
        child: Text('No programs available',
            style: GoogleFonts.sora(color: Colors.white38, fontSize: 13)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: _programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final program = _programs[i];
        return _DvrProgramRow(
          program: program,
          onTap: () {
            final link = program.sources.getPreferredVideoSource() ?? '';
            if (link.isNotEmpty) {
              widget.updateVideoController(link);
            }
            _closeDvr();
          },
        );
      },
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
// ARCHIVE BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _ArchiveButton extends StatelessWidget {
  final VoidCallback onTap;
  final FocusNode focusNode;

  const _ArchiveButton({required this.onTap, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        focusNode: focusNode,
        borderRadius: BorderRadius.circular(10),
        focusColor: Colors.white.withValues(alpha: 0.2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(
                'Archive',
                style: GoogleFonts.sora(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DVR DATE CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _DvrDateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DvrDateChip(
      {required this.date, required this.isSelected, required this.onTap});

  String get _label {
    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) return 'Yesterday';
    return DateFormat('EEE d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      focusColor: Colors.transparent,
      child: Builder(builder: (context) {
        final hasFocus = Focus.of(context).hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFA83734)
                : hasFocus
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected || hasFocus
                  ? const Color(0xFFA83734)
                  : Colors.white.withValues(alpha: 0.15),
              width: hasFocus ? 2 : 1,
            ),
          ),
          child: Text(
            _label,
            style: GoogleFonts.sora(
              color: isSelected || hasFocus ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight:
                  isSelected || hasFocus ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DVR PROGRAM ROW
// ═══════════════════════════════════════════════════════════════════════════

String _dvrFmtTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return '';
  }
}

class _DvrProgramRow extends StatelessWidget {
  final LiveModel program;
  final VoidCallback onTap;

  const _DvrProgramRow({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = _dvrFmtTime(program.startsAt);
    final end = _dvrFmtTime(program.endsAt);
    final timeRange = end.isEmpty ? start : '$start – $end';

    final now = DateTime.now();
    final isCurrent = () {
      final s = program.startsAt, e = program.endsAt;
      if (s == null || s.isEmpty || e == null || e.isEmpty) return false;
      try {
        final st = DateTime.parse(s).toLocal();
        final en = DateTime.parse(e).toLocal();
        return !now.isBefore(st) && now.isBefore(en);
      } catch (_) {
        return false;
      }
    }();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        focusColor: Colors.transparent,
        onTap: onTap,
        child: Builder(builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isFocused
                  ? Colors.white.withValues(alpha: 0.15)
                  : isCurrent
                      ? const Color(0xFFA83734).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFocused
                    ? Colors.white.withValues(alpha: 0.7)
                    : isCurrent
                        ? const Color(0xFFA83734).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (timeRange.isNotEmpty) ...[
                  SizedBox(
                    width: 90,
                    child: Text(
                      timeRange,
                      style: GoogleFonts.sora(
                        color: isCurrent
                            ? const Color(0xFFFF8A8A)
                            : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 28,
                      color: Colors.white12,
                      margin: const EdgeInsets.symmetric(horizontal: 10)),
                ],
                Expanded(
                  child: Text(
                    program.title,
                    style: GoogleFonts.sora(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.play_circle_outline_rounded,
                    color: Colors.white38, size: 20),
              ],
            ),
          );
        }),
      ),
    );
  }
}
