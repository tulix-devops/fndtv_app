import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/ui/widgets/chewie_player/chewie_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:ui_kit/ui_kit.dart';

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
            padding: EdgeInsets.fromLTRB(
                4, MediaQuery.of(context).padding.top + 8, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 26),
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
                    child: ChewiePlayer(url: link),
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
                      _DateChip(
                        date: _selectedDate,
                        colors: colors,
                      ),
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
              child:
                  Text(context.l.retry, style: TextStyle(color: colors.accent)),
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
          childAspectRatio: 0.82,
        ),
        itemCount: _programs.length,
        itemBuilder: (context, i) => _DvrGridCard(
            program: _programs[i], isCurrent: isCurrent(_programs[i])),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 14),
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

  const _ViewToggle(
      {required this.isGrid, required this.onChanged, required this.colors});

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
        child:
            Icon(icon, size: 18, color: active ? Colors.white : colors.accent),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATE CHIP
// ═══════════════════════════════════════════════════════════════════════════

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
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INLINE MINI PLAYER (self-contained video_player + chewie)
// ═══════════════════════════════════════════════════════════════════════════

String _fmtTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    return DateFormat('HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return '';
  }
}

Color _scheduleCardBackground(UiKitColors colors, bool isCurrent) {
  if (isCurrent) {
    return Color.lerp(colors.accent, colors.bgCard, 0.22)!;
  }
  return colors.bgCardHover;
}

Color _scheduleCardBorder(UiKitColors colors, bool isCurrent) {
  if (isCurrent) return colors.accentHover;
  return colors.borderStrong.withValues(alpha: 0.7);
}

Color _scheduleCardTimeColor(UiKitColors colors, bool isCurrent) {
  return isCurrent ? Colors.white : colors.accentHover;
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

    final cardBackground = _scheduleCardBackground(colors, isCurrent);
    final cardBorder = _scheduleCardBorder(colors, isCurrent);
    final titleColor = isCurrent ? Colors.white : colors.textPrimary;
    final timeColor = _scheduleCardTimeColor(colors, isCurrent);
    final range = end.isEmpty ? start : '$start - $end';

    return Container(
      height: 62,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: 1,
          color: cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 88,
              height: 50,
              child: hasThumb
                  ? Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.bgHero,
                        child: Icon(Icons.live_tv_rounded,
                            color: colors.textHint, size: 22),
                      ),
                    )
                  : Container(
                      color: colors.bgHero,
                      child: Icon(Icons.live_tv_rounded,
                          color: colors.textHint, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 7),
          // Title (secondary — trimmed to a single line)
          Expanded(
            child: Text(
              program.title,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Time range (primary — full range, prominent)
          if (range.isNotEmpty)
            Text(
              range,
              style: GoogleFonts.sora(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: timeColor,
              ),
            ),
        ],
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
    final range = end.isEmpty ? start : '$start - $end';

    final cardBackground = _scheduleCardBackground(colors, isCurrent);
    final cardBorder = _scheduleCardBorder(colors, isCurrent);
    final titleColor = isCurrent ? Colors.white : colors.textPrimary;
    final timeColor = _scheduleCardTimeColor(colors, isCurrent);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          width: 1,
          color: cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasThumb
                  ? Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.bgHero,
                        child: Icon(Icons.live_tv_rounded,
                            color: colors.textHint, size: 26),
                      ),
                    )
                  : Container(
                      color: colors.bgHero,
                      child: Icon(Icons.live_tv_rounded,
                          color: colors.textHint, size: 26),
                    ),
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
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              program.title,
              style: GoogleFonts.sora(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.25,
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
