import 'dart:async';

import 'package:app_focus/app_focus.dart';
import 'package:commons/commons.dart';
import 'package:intl/intl.dart';
import 'package:fndtv/src/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fndtv/src/data/services/dynamic_channel_service.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';

//

class AppView extends StatefulWidget {
  static const path = '/home';
  static const name = 'app-view';
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppVersion();
      _applyOrientation();
    });
  }

  void _applyOrientation() {
    if (context.isTv) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  Future<void> _fetchAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = info.version;
        print(info.version);
      });
    } catch (_) {
      // ignore
    }
  }

  String getTitle() {
    return 'WATC TV 57';
  }

  @override
  Widget build(BuildContext context) {
    final String title = getTitle();

    return FutureBuilder<List<LiveModel>>(
      future: DynamicChannelService.getChannels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppAuthDialogListener(
            child: AppFocusGroup(
              child: AppScaffold(
                hasNavbar: false,
                body: const Center(
                  child: AppLoadingIndicator(size: 60),
                ),
              ),
            ),
          );
        }

        final channels = snapshot.data ?? [];

        return _buildMainContent(context, title, channels);
      },
    );
  }

  Widget _buildMainContent(
      BuildContext context, String title, List<LiveModel> channels) {
    return AppAuthDialogListener(
      child: AppFocusGroup(
        child: AppScaffold(
          hasNavbar: false, // Remove navigation bar since we only have one tab
          body: Column(
            children: [
              if (context.isTv) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        Assets.logo,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: context.uiColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        title,
                        style: TextStyles.h4,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 10,
                      ),
                      if (_appVersion != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            'Version $_appVersion',
                            style: TextStyles.bodyMedium.copyWith(
                              color:
                                  context.uiColors.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      const SizedBox(
                        width: 5,
                      ),
                      BlocBuilder<AppCubit, AppState>(
                        builder: (context, state) {
                          final customerInfo = state.customerInfo;
                          print(customerInfo);
                          if (customerInfo != null && state.isAuthenticated) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    context.uiColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      context.uiColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: context.uiColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        customerInfo.email,
                                        style: TextStyles.bodySmall.copyWith(
                                          color: context.uiColors.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      const TimerWidget(),
                      const SizedBox(
                        width: 40,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                _MobileAppHeader(title: title),
              ],
              Expanded(
                child: StaticHomePage(channels: channels),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  String _formattedDate = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _formattedDate = DateFormat('HH:mm:ss \n EEE d MMM').format(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formattedDate,
      style: TextStyles.h5,
    );
  }
}

// ─── Mobile app header ────────────────────────────────────────────────────────

class _MobileAppHeader extends StatelessWidget {
  const _MobileAppHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Image.asset(Assets.logo, height: 36, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: context.uiColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyles.h6),
          const Spacer(),
          BlocBuilder<AppCubit, AppState>(
            builder: (context, state) {
              if (state.isAuthenticated && state.customerInfo != null) {
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.uiColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: context.uiColors.primary,
                    size: 20,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Static Home Page ────────────────────────────────────────────────────────

class StaticHomePage extends StatelessWidget {
  const StaticHomePage({super.key, required this.channels});

  final List<LiveModel> channels;

  @override
  Widget build(BuildContext context) {
    return DeviceWrapper(
      widget: _MobileStaticChannelList(channels: channels),
      tvWidget: _TVStaticChannelList(channels: channels),
    );
  }
}

// ─── Mobile channel list ────────────────────────────────────────────────────

class _MobileStaticChannelList extends StatelessWidget {
  const _MobileStaticChannelList({required this.channels});

  final List<LiveModel> channels;

  void _onCardTapped(BuildContext context, int index) {
    Navigator.of(context).pushNamed(
      MobileChannelDetailPage.path,
      arguments: {
        'channel': channels[index],
        'contentType': ContentType.television,
        'contentCubit':
            context.read<ContentCubit>(), // Use existing cubit instance
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

// ─── TV channel list ─────────────────────────────────────────────────────────

class _TVStaticChannelList extends StatefulWidget {
  const _TVStaticChannelList({required this.channels});
  final List<LiveModel> channels;
  @override
  State<_TVStaticChannelList> createState() => __TVStaticChannelListState();
}

class __TVStaticChannelListState extends State<_TVStaticChannelList> {
  final int _crossAxisCount = 4;

  late List<FocusNode> _cardFocusNodes;
  final ScrollController controller = ScrollController();

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
    _cardFocusNodes =
        List.generate(widget.channels.length, (index) => FocusNode());

    for (var node in _cardFocusNodes) {
      node.addListener(() => listener(node));
    }

    if (_cardFocusNodes.isNotEmpty) {
      _cardFocusNodes.first.requestFocus();
    }
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
    Navigator.of(context).pushNamed(
      VideoPlayerPage.path,
      arguments: {
        'contentType': ContentType.television,
        'channel': widget.channels[cardIndex],
        'contentCubit':
            context.read<ContentCubit>() // Use existing cubit instance
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
                    color: hasFocus
                        ? context.uiColors.primary
                        : Colors.transparent,
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
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : Container(color: AppColors.greyscale[500])
                                    .animate()
                                    .shimmer(
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
