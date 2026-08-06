import 'package:chewie/chewie.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
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
