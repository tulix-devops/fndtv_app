import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/pages/video_player/video_player_page.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MobileChannelDetailPage extends StatefulWidget {
  const MobileChannelDetailPage({
    super.key,
    required this.video,
    required this.contentType,
  });

  final LiveModel video;
  final ContentType contentType;

  static const name = 'mobile-channel-detail';
  static const path = 'mobile-channel-detail';

  @override
  State<MobileChannelDetailPage> createState() => _MobileChannelDetailPageState();
}

class _MobileChannelDetailPageState extends State<MobileChannelDetailPage> {
  String _selectedDay = '';
  DvrItemModel? _selectedDvrItem;
  String? _dvrLink;
  bool get _isWatchingDvr => _dvrLink != null;

  String get _activeLink => _dvrLink ?? widget.video.sources.getPreferredVideoSource() ?? '';

  @override
  void initState() {
    super.initState();
    print(widget.video.sources);
    final dvrUrl = widget.video.dvrUrl;
    if (dvrUrl != null && dvrUrl.isNotEmpty) {
      context.read<ContentCubit>().getDvrDataFromUrl(dvrUrl: dvrUrl);
    }
  }

  void _selectDvrItem(DvrItemModel item) {
    if (item.isFuture) return;
    setState(() {
      _selectedDvrItem = item;
      _dvrLink = item.stream;
    });
  }

  void _goLive() {
    setState(() {
      _selectedDvrItem = null;
      _dvrLink = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.uiColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _ChannelHeader(
              title: widget.video.title,
              onBack: () => Navigator.of(context).pop(),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _EmbeddedVideoPlayer(
                key: ValueKey(_activeLink),
                link: _activeLink,
                isLive: !_isWatchingDvr,
                video: widget.video,
                contentType: widget.contentType,
              ),
            ),
            if (_isWatchingDvr) _GoLiveButton(onGoLive: _goLive),
            Expanded(
              child: BlocBuilder<ContentCubit, ContentState>(
                builder: (context, state) {
                  final hasDvr = widget.video.dvrUrl != null && widget.video.dvrUrl!.isNotEmpty;

                  if (!hasDvr) {
                    return _InfoSection(
                      video: widget.video,
                      description: widget.video.description ?? '',
                    );
                  }

                  if (state.dvrStatus == Status.loading) {
                    return const Center(child: AppLoadingIndicator(size: 50));
                  }

                  final seriesData = state.dvrData?.itemsByDay;
                  if (seriesData == null || seriesData.isEmpty) {
                    return _InfoSection(
                      video: widget.video,
                      description: widget.video.description ?? '',
                    );
                  }

                  final effectiveDay = seriesData.containsKey(_selectedDay) ? _selectedDay : seriesData.keys.first;

                  if (effectiveDay != _selectedDay) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedDay = effectiveDay);
                    });
                  }

                  return Column(
                    children: [
                      _DaySelector(
                        days: seriesData.keys.toList(),
                        selectedDay: effectiveDay,
                        onDaySelected: (day) => setState(() => _selectedDay = day),
                      ),
                      Divider(
                        height: 1,
                        color: context.uiColors.onSurface.withOpacity(0.1),
                      ),
                      Expanded(
                        child: _DvrProgramList(
                          items: seriesData[effectiveDay] ?? [],
                          selectedItem: _selectedDvrItem,
                          onItemTap: _selectDvrItem,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyles.h6,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Go Live Button
// ─────────────────────────────────────────────────────────────────────────────

class _GoLiveButton extends StatelessWidget {
  const _GoLiveButton({required this.onGoLive});

  final VoidCallback onGoLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.uiColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onGoLive,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.uiColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.white, size: 8),
              SizedBox(width: 8),
              Text(
                'GO LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info section (no DVR)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.video, required this.description});

  final LiveModel video;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel info with image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel thumbnail/logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // color: context.uiColors.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    video.images.getThumbnail(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: context.uiColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tv,
                          color: context.uiColors.onSurface.withOpacity(0.5),
                          size: 32,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: context.uiColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.uiColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Channel title and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyles.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // About section
          if (description.isNotEmpty) ...[
            Text('About', style: TextStyles.bodyLargeBold),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyles.bodyMedium.copyWith(
                color: context.uiColors.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ] else ...[
            Text('About', style: TextStyles.bodyLargeBold),
            const SizedBox(height: 8),
            Text(
              'Live streaming channel - Watch ${video.title} live.',
              style: TextStyles.bodyMedium.copyWith(
                color: context.uiColors.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day selector chips
// ─────────────────────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<String> days;
  final String selectedDay;
  final ValueChanged<String> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;
          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? context.uiColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? context.uiColors.primary : context.uiColors.onSurface.withOpacity(0.25),
                ),
              ),
              child: Center(
                child: Text(
                  day,
                  style: TextStyles.bodySmallMedium.copyWith(
                    color: isSelected ? Colors.white : context.uiColors.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DVR program list
// ─────────────────────────────────────────────────────────────────────────────

class _DvrProgramList extends StatelessWidget {
  const _DvrProgramList({
    required this.items,
    required this.selectedItem,
    required this.onItemTap,
  });

  final List<DvrItemModel> items;
  final DvrItemModel? selectedItem;
  final ValueChanged<DvrItemModel> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No programs for this day',
          style: TextStyles.bodyMedium.copyWith(
            color: context.uiColors.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: context.uiColors.onSurface.withOpacity(0.08),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DvrProgramTile(
          item: item,
          isSelected: selectedItem?.id == item.id,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DVR program tile
// ─────────────────────────────────────────────────────────────────────────────

class _DvrProgramTile extends StatelessWidget {
  const _DvrProgramTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DvrItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canPlay = !item.isFuture;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected ? context.uiColors.primary.withOpacity(0.12) : Colors.transparent,
        border: isSelected ? Border(left: BorderSide(color: context.uiColors.primary, width: 3)) : const Border(),
      ),
      child: InkWell(
        onTap: canPlay ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _ThumbCell(thumb: item.displayThumb),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      style: TextStyles.bodyMediumBold.copyWith(
                        color: isSelected ? context.uiColors.primary : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: context.uiColors.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.formattedStartTime} \u2013 ${item.formattedEndTime}',
                          style: TextStyles.bodySmall.copyWith(
                            color: context.uiColors.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (item.duration != null && item.duration!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _DurationBadge(duration: item.duration!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Icon(Icons.play_circle_fill_rounded, color: context.uiColors.primary, size: 28)
              else if (canPlay)
                Icon(Icons.play_circle_outline_rounded, color: context.uiColors.onSurface.withOpacity(0.4), size: 26)
              else
                Icon(Icons.schedule_rounded, color: context.uiColors.onSurface.withOpacity(0.3), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbCell extends StatelessWidget {
  const _ThumbCell({required this.thumb});

  final String thumb;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 88,
        height: 58,
        child: thumb.isNotEmpty
            ? Image.network(
                thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbPlaceholder(),
              )
            : const _ThumbPlaceholder(),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.uiColors.tvSurface,
      child: Center(
        child: Icon(
          Icons.tv_rounded,
          color: context.uiColors.onSurface.withOpacity(0.3),
          size: 24,
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: context.uiColors.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        duration,
        style: TextStyles.bodyXSmallMedium.copyWith(
          color: context.uiColors.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _EmbeddedVideoPlayer extends StatefulWidget {
  const _EmbeddedVideoPlayer({
    super.key,
    required this.link,
    required this.isLive,
    required this.video,
    required this.contentType,
  });

  final String link;
  final bool isLive;
  final LiveModel video;
  final ContentType contentType;

  @override
  State<_EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<_EmbeddedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initPlayer(widget.link);
  }

  void _initPlayer(String link) {
    if (link.isEmpty) return;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(link),
      formatHint: VideoFormat.hls,
    )..initialize().then((_) {
        if (!mounted) return;
        _controller?.addListener(_onUpdate);
        setState(() => _isInitialized = true);
        _controller?.play();
        _controller?.setLooping(false);
        _controller?.setVolume(1.0);
      });
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller?.removeListener(_onUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    setState(() => _showControls = !_showControls);
  }

  void _openFullscreen() {
    Navigator.of(context).pushNamed(
      VideoPlayerPage.path,
      arguments: {
        'channel': widget.video,
        'contentType': widget.contentType,
        'contentCubit': context.read<ContentCubit>(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: context.uiColors.primary),
        ),
      );
    }

    final isPlaying = _controller!.value.isPlaying;
    final isBuffering = _controller!.value.isBuffering;

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_controller!),
            if (isBuffering)
              Center(
                child: CircularProgressIndicator(color: context.uiColors.primary),
              ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: _PlayerOverlay(
                isPlaying: isPlaying,
                isLive: widget.isLive,
                onPlayPause: _togglePlayPause,
                onFullscreen: _openFullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Player overlay controls
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerOverlay extends StatelessWidget {
  const _PlayerOverlay({
    required this.isPlaying,
    required this.isLive,
    required this.onPlayPause,
    required this.onFullscreen,
  });

  final bool isPlaying;
  final bool isLive;
  final VoidCallback onPlayPause;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66000000),
            Colors.transparent,
            Color(0x99000000),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: onPlayPause,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          if (isLive)
            Positioned(
              top: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: context.uiColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            right: 10,
            child: GestureDetector(
              onTap: onFullscreen,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
