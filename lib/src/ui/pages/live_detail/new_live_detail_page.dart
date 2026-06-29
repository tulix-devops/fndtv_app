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
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
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
  DateTime _selectedDate = DateTime.now();
  List<LiveModel> _programs = const [];

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_programs.length, (_) => FocusNode());
    _fetchSchedule();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 14)),
      lastDate: now.add(const Duration(days: 14)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _loading = true;
        _error = false;
      });
      _fetchSchedule();
    }
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

  late List<FocusNode> _focusNodes;

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final link = widget.channel.sources.getPreferredVideoSource() ?? '';
    final isTv = context.isTv;

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

          Expanded(
            child: isTv
                ? _buildTvContent(context, colors, link)
                : _buildMobileContent(context, colors, link),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────
  Widget _buildMobileContent(
      BuildContext context, UiKitColors colors, String link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _InlineLivePlayer(url: link),
          ),
        ),
        const SizedBox(height: 16),
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
                onTap: _pickDate,
                colors: colors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildScheduleBody(colors)),
      ],
    );
  }

  // ── TV layout: player + info (left) | schedule (right) ────────────────────
  Widget _buildTvContent(
      BuildContext context, UiKitColors colors, String link) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel ── player + channel badge
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _InlineLivePlayer(url: link),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.channel.title,
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l.badgeLive,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(width: 1, color: colors.border.withValues(alpha: 0.5)),

          // Right panel ── schedule
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        context.l.archive,
                        style: GoogleFonts.sora(
                          fontSize: 20,
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
                        onTap: _pickDate,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
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
          program: _programs[i],
          isCurrent: isCurrent(_programs[i]),
          onTap: () => openLiveDetail(context, _programs[i]),
        ),
      );
    }
    _focusNodes = List.generate(_programs.length, (_) => FocusNode());

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _DvrRow(
        program: _programs[i],
        isCurrent: isCurrent(_programs[i]),
        onTap: () => openLiveDetail(context, _programs[i]),
      ),
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
    final radius = BorderRadius.horizontal(
      left: left ? const Radius.circular(9) : Radius.zero,
      right: left ? Radius.zero : const Radius.circular(9),
    );
    return Material(
      color: active ? colors.accent : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        focusColor: colors.accent.withValues(alpha: 0.3),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Icon(icon,
              size: 18, color: active ? Colors.white : colors.accent),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATE CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _DateChip extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  final UiKitColors colors;

  const _DateChip(
      {required this.date, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        focusColor: colors.accent.withValues(alpha: 0.2),
        onTap: onTap,
        child: Container(
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
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: colors.accent),
            ],
          ),
        ),
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
                child: Icon(Icons.videocam_off_rounded,
                    color: Colors.white54, size: 36),
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
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const _DvrRow(
      {required this.program,
      this.isCurrent = false,
      this.onTap,
      this.focusNode});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final thumb = program.images.getThumbnail();
    final hasThumb = thumb.isNotEmpty && thumb != defaultPosterImage;
    final start = _fmtTime(program.startsAt);
    final end = _fmtTime(program.endsAt);

    final titleColor = isCurrent ? Colors.white : colors.textMuted;
    final timeColor = isCurrent ? Colors.white : colors.accent;
    final range = end.isEmpty ? start : '$start - $end';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        focusNode: focusNode,
        focusColor: Colors.white.withValues(alpha: 0.15),
        onTap: onTap,
        child: Builder(builder: (context) {
          final isFocused = Focus.of(context).hasFocus ||
              focusNode?.hasFocus == true; // for TV remote focus
          return Container(
            height: 62,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isFocused ? colors.accent : const Color(0xFFF6E3E3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                width: 1,
                color: isFocused ? colors.accent : const Color(0xFFE2B6B6),
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
                              color: colors.bgSurface,
                              child: Icon(Icons.live_tv_rounded,
                                  color: colors.textMuted, size: 22),
                            ),
                          )
                        : Container(
                            color: colors.bgSurface,
                            child: Icon(Icons.live_tv_rounded,
                                color: colors.textMuted, size: 22),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(
                    program.title,
                    style: GoogleFonts.sora(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                // Time range
                if (range.isNotEmpty)
                  Text(
                    range,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: timeColor,
                    ),
                  ),
              ],
            ),
          );
        }),
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
  final VoidCallback? onTap;

  const _DvrGridCard({
    required this.program,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final thumb = program.images.getThumbnail();
    final hasThumb = thumb.isNotEmpty && thumb != defaultPosterImage;
    final start = _fmtTime(program.startsAt);
    final end = _fmtTime(program.endsAt);
    final range = end.isEmpty ? start : '$start - $end';

    final titleColor = isCurrent ? Colors.white : colors.textPrimary;
    final timeColor = isCurrent ? Colors.white : colors.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        focusColor: Colors.white.withValues(alpha: 0.15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrent ? colors.accent : const Color(0xFFF6E3E3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              width: 1,
              color: isCurrent ? colors.accent : const Color(0xFFE2B6B6),
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
                            color: colors.bgSurface,
                            child: Icon(Icons.live_tv_rounded,
                                color: colors.textMuted, size: 26),
                          ),
                        )
                      : Container(
                          color: colors.bgSurface,
                          child: Icon(Icons.live_tv_rounded,
                              color: colors.textMuted, size: 26),
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
        ),
      ),
    );
  }
}
