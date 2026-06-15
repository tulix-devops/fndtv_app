import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/ui/pages/channel_detail/mobile_channel_detail_page.dart';
import 'package:fndtv/src/utils/content_type_mapper.dart';

import 'package:ui_kit/ui_kit.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.contentTypeId,
  });

  final int contentTypeId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch content for this type when page loads
    context.read<ContentCubit>().getContentForType(widget.contentTypeId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        final contentList = state.contentList?['${widget.contentTypeId}']?.data;
        final isLoading = contentList == null || contentList.isEmpty;

        return AppStatusWidget(
          status: state.status,
          loaderWidget: const Center(child: AppLoadingIndicator(size: 70)),
          errorWidget: const CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: Center(child: Text('An error occurred')),
              ),
            ],
          ),
          widget: isLoading
              ? const Center(child: AppLoadingIndicator(size: 70))
              : DeviceWrapper(
                  widget: _MobileHomePageCardList(
                    channels: contentList,
                    contentTypeId: widget.contentTypeId,
                  ),
                  tvWidget: _HomePageCardList(
                    channels: contentList,
                    contentTypeId: widget.contentTypeId,
                  ),
                ),
        );
      },
    );
  }
}

// ─── Mobile card grid ───────────────────────────────────────────────────────

class _MobileHomePageCardList extends StatelessWidget {
  const _MobileHomePageCardList({required this.channels, required this.contentTypeId});

  final List<LiveModel> channels;
  final int contentTypeId;

  void _onCardTapped(BuildContext context, int index) {
    final contentType = contentTypeId.toContentType();
    if (contentType == null) return;

    Navigator.of(context).pushNamed(
      MobileChannelDetailPage.path,
      arguments: {
        'channel': channels[index],
        'contentType': contentType,
        'contentCubit': context.read<ContentCubit>(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
      itemCount: channels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final item = channels[index];
        return _MobileChannelCard(
          item: item,
          onTap: () => _onCardTapped(context, index),
        );
      },
    );
  }
}

class _MobileChannelCard extends StatelessWidget {
  const _MobileChannelCard({required this.item, required this.onTap});

  final LiveModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: context.uiColors.tvSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item.images.getThumbnail(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        Assets.logo,
                        fit: BoxFit.contain,
                      ),
                      loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null
                              ? child
                              : Container(color: context.uiColors.tvSurface)
                                  .animate()
                                  .shimmer(
                                    colors: [
                                      Colors.black,
                                      context.uiColors.primary,
                                      Colors.black,
                                    ],
                                  ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  item.title,
                  style: TextStyles.bodySmallMedium,
                  maxLines: 1,
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

// ─── TV card grid ────────────────────────────────────────────────────────────

class _HomePageCardList extends StatefulWidget {
  const _HomePageCardList({required this.channels, required this.contentTypeId});
  final List<LiveModel> channels;
  final int contentTypeId;
  @override
  State<_HomePageCardList> createState() => __HomePageCardListState();
}

class __HomePageCardListState extends State<_HomePageCardList> {
  final int _crossAxisCount = 4;

  late List<FocusNode> _cardFocusNodes;
  final ScrollController controller = ScrollController();
  double position = 0;

  void listener(FocusNode focus) {
    if (focus.hasFocus) {
      Scrollable.ensureVisible(
        focus.context!,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cardFocusNodes = List.generate(widget.channels.length, (index) => FocusNode());

    for (var node in _cardFocusNodes) {
      node.addListener(() => listener(node));
    }

    _cardFocusNodes.first.requestFocus();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int cardIndex) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    const itemsPerRow = 4;
    final totalItems = _cardFocusNodes.length;

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        if (cardIndex % itemsPerRow == 0) {
          FocusScope.of(context).focusInDirection(TraversalDirection.left);
          return KeyEventResult.handled;
        } else {
          _cardFocusNodes[cardIndex - 1].requestFocus();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
        if (cardIndex < totalItems - 1) {
          _cardFocusNodes[cardIndex + 1].requestFocus();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        if (cardIndex >= itemsPerRow) {
          _cardFocusNodes[cardIndex - itemsPerRow].requestFocus();
        } else {
          // If we're in the top row, try to focus on header elements
          FocusScope.of(context).focusInDirection(TraversalDirection.up);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        final nextIndex = cardIndex + itemsPerRow;
        if (nextIndex < totalItems) {
          _cardFocusNodes[nextIndex].requestFocus();
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.enter || LogicalKeyboardKey.select:
        _handleEnterAction(cardIndex);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handleEnterAction(int cardIndex) async {
    // Convert contentTypeId to ContentType enum
    final contentType = widget.contentTypeId.toContentType();

    if (contentType == null) {
      print('Error: Unable to map contentTypeId ${widget.contentTypeId} to ContentType enum');
      return;
    }

    Navigator.of(context).pushNamed(
      VideoPlayerPage.path,
      arguments: {
        'contentType': contentType,
        'channel': widget.channels[cardIndex],
        'contentCubit': context.read<ContentCubit>()
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.only(left: 8, top: 65, right: 8, bottom: 100),
      itemCount: widget.channels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = widget.channels[index];
        return Focus(
          focusNode: _cardFocusNodes[index],
          onFocusChange: (hasFocus) {
            setState(() {});
          },
          onKeyEvent: (_, event) => _handleKeyEvent(event, index),
          child: Builder(
            builder: (context) {
              final bool hasFocus = Focus.of(context).hasFocus;
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: hasFocus ? context.uiColors.primary : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.network(
                        item.images.getThumbnail(),
                        fit: BoxFit.fill,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Image.asset(Assets.logo),
                        loadingBuilder: (context, child, loadingProgress) => loadingProgress == null
                            ? child
                            : Container(color: AppColors.greyscale[500]).animate().shimmer(
                                colors: [
                                  Colors.black,
                                  context.uiColors.primary,
                                  Colors.black,
                                ],
                              ).fadeIn(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: TextStyles.h5.copyWith(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final focusNode in _cardFocusNodes) {
      focusNode.removeListener(() => listener(focusNode));
      focusNode.dispose();
    }
  }
}
