import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/source_model.dart';
import 'package:fndtv/src/ui/pages/video_player/video_player_page.dart';
import 'package:ui_kit/ui_kit.dart';

/// Regular DVR card grid without download functionality
class DvrCardGrid extends StatefulWidget {
  const DvrCardGrid({
    super.key,
    required this.seriesData,
    required this.selectedDay,
    required this.dvrFocus,
    required this.cardContainerFocus,
    required this.controller,
    required this.contentCubit,
  });

  final Map<String, List<DvrItemModel>> seriesData;
  final String selectedDay;
  final FocusNode cardContainerFocus;
  final FocusNode dvrFocus;
  final ScrollController controller;
  final ContentCubit contentCubit;

  @override
  State<DvrCardGrid> createState() => _DvrCardGridState();
}

class _DvrCardGridState extends State<DvrCardGrid> {
  int _currentCardIndex = 0;
  final int _crossAxisCount = 3;

  // Focus nodes for each card
  final List<GlobalKey> _cardKeys = [];

  @override
  void initState() {
    super.initState();
    _initializeCardKeys();
  }

  void _initializeCardKeys() {
    final itemCount = widget.seriesData[widget.selectedDay]?.length ?? 0;
    _cardKeys.clear();
    for (int i = 0; i < itemCount; i++) {
      _cardKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(DvrCardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _currentCardIndex = 0;
      _initializeCardKeys();
    }
  }

  void _ensureVisible() {
    if (_currentCardIndex < _cardKeys.length) {
      final key = _cardKeys[_currentCardIndex];
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    final totalItems = widget.seriesData[widget.selectedDay]!.length;

    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      setState(() {
        if (key == LogicalKeyboardKey.arrowRight) {
          if ((_currentCardIndex + 1) % _crossAxisCount != 0 && _currentCardIndex < totalItems - 1) {
            _currentCardIndex++;
            _ensureVisible();
          }
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          if (_currentCardIndex % _crossAxisCount == 0) {
            widget.dvrFocus.requestFocus();
          } else if (_currentCardIndex % _crossAxisCount != 0) {
            _currentCardIndex--;
            _ensureVisible();
          }
        } else if (key == LogicalKeyboardKey.arrowDown) {
          final newIndex = _currentCardIndex + _crossAxisCount;
          if (newIndex < totalItems) {
            _currentCardIndex = newIndex;
            _ensureVisible();
          }
        } else if (key == LogicalKeyboardKey.arrowUp) {
          final newIndex = _currentCardIndex - _crossAxisCount;
          if (newIndex >= 0) {
            _currentCardIndex = newIndex;
            _ensureVisible();
          }
        } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
          final item = widget.seriesData[widget.selectedDay]![_currentCardIndex];
          if (!item.isFuture) {
            // Play the DVR content
            Navigator.of(context).pushNamed(
              VideoPlayerPage.path,
              arguments: {
                'channel': LiveModel(
                  id: item.id,
                  title: item.title,
                  description: item.descr,
                  images: ImagesModel(
                    thumbnail: item.displayThumb,
                    banner: item.displayThumb,
                    poster: item.displayThumb,
                  ),
                  sources: SourceModel(
                    id: item.id,
                    primary: item.stream,
                    secondary: item.stream,
                    trailer: item.stream,
                    hls: item.stream,
                    dash: item.stream,
                    file: item.stream,
                  ),
                  type: '',
                  typeId: 0,
                  live: false,
                ),
                'contentType': ContentType.dvr,
                'contentCubit': widget.contentCubit,
              },
            );
          }
        }
      });

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.seriesData[widget.selectedDay]!;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Focus(
        focusNode: widget.cardContainerFocus,
        onFocusChange: (_) => setState(() {}),
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: GridView.builder(
          controller: widget.controller,
          padding: const EdgeInsets.all(8),
          itemCount: items.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return const SizedBox(height: 100);
            }

            final item = items[index];
            final isFocused = index == _currentCardIndex && widget.cardContainerFocus.hasFocus;

            return Container(
              key: _cardKeys[index],
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: isFocused ? context.uiColors.onSurface : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.network(
                      item.thumb ?? '',
                      fit: BoxFit.fill,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
                          ? child
                          : Container(
                              color: AppColors.greyscale[500],
                            ).animate().shimmer(colors: [
                              Colors.black,
                              context.uiColors.primary,
                              Colors.black,
                            ]).fadeIn(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.displayTitle,
                    style: TextStyles.bodyLarge.copyWith(
                      color: item.isFuture ? AppColors.greyscale[500] : context.uiColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.formattedStartTime} - ${item.formattedEndTime}',
                    style: TextStyles.bodyMedium.copyWith(
                      color: item.isFuture ? AppColors.greyscale[500] : context.uiColors.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
