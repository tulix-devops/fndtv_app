import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:fndtv/src/ui/widgets/app_scaffold.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/widgets/dvr_card_grid.dart';
import 'package:ui_kit/ui_kit.dart';

/// DVR page - uses download version by default
/// Switch to DvrCardGrid if you don't need download functionality
class DvrPage extends StatefulWidget {
  const DvrPage({
    super.key,
    this.dvrUrl,
    this.isOverlay = false,
    this.onClose,
  });

  final String? dvrUrl;
  final bool isOverlay;
  final VoidCallback? onClose;

  static const path = 'dvr';

  @override
  State<DvrPage> createState() => _DvrPageState();
}

class _DvrPageState extends State<DvrPage> {
  int _currentPage = 0;
  String _selectedDay = '';

  final FocusNode dvrFocus = FocusNode();
  final FocusNode cardContainerFocus = FocusNode();
  late FocusNode focusWrapper;

  Map<String, List<DvrItemModel>>? seriesData;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _containerController = ScrollController();
  final List<GlobalKey> _dayKeys = [];

  late DvrItemModel dummyItem;
  final today = DateTime.now();

  @override
  void initState() {
    super.initState();
    focusWrapper = FocusNode();
    dummyItem = DvrItemModel(
      id: 0,
      title: '',
      descr: '',
      thumb: '',
      stream: '',
    );

    final dvrUrl = widget.dvrUrl;
    if (dvrUrl != null && dvrUrl.isNotEmpty) {
      context.read<ContentCubit>().getDvrDataFromUrl(dvrUrl: dvrUrl);
    }
    focusWrapper.requestFocus();
  }

  @override
  void dispose() {
    dvrFocus.dispose();
    cardContainerFocus.dispose();
    focusWrapper.dispose();
    _scrollController.dispose();
    _containerController.dispose();
    super.dispose();
  }

  void _initializeDayKeys() {
    _dayKeys.clear();
    final keyCount = seriesData?.keys.length ?? 0;
    for (int i = 0; i < keyCount; i++) {
      _dayKeys.add(GlobalKey());
    }
  }

  void _ensureDayVisible() {
    if (_currentPage < _dayKeys.length) {
      final key = _dayKeys[_currentPage];
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

  String? _findTodaysDate() {
    if (seriesData == null) return null;
    final todayLabel = dummyItem.dateLabel;
    return seriesData!.keys.contains(todayLabel) ? todayLabel : null;
  }

  bool _isToday(String dateKey) {
    return dateKey == dummyItem.dateLabel;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (state.dvrStatus == Status.loading) {
          return widget.isOverlay
              ? Container(
                  color: Colors.black.withOpacity(0.9),
                  child: const Center(child: AppLoadingIndicator(size: 70)),
                )
              : const AppScaffold(
                  body: Center(child: AppLoadingIndicator(size: 70)),
                );
        }

        if (state.dvrStatus == Status.failure) {
          return widget.isOverlay
              ? Container(
                  color: Colors.black.withOpacity(0.9),
                  child: const Center(child: Text('Failed to load DVR data')),
                )
              : const AppScaffold(
                  body: Center(child: Text('Failed to load DVR data')),
                );
        }

        final dvrData = state.dvrData;
        if (dvrData == null) {
          return widget.isOverlay
              ? Container(
                  color: Colors.black.withOpacity(0.9),
                  child: const Center(child: Text('No DVR data available')),
                )
              : const AppScaffold(
                  body: Center(child: Text('No DVR data available')),
                );
        }

        seriesData = dvrData.itemsByDay;

        if (seriesData == null || seriesData!.isEmpty) {
          return widget.isOverlay
              ? Container(
                  color: Colors.black.withOpacity(0.9),
                  child: const Center(child: Text('No DVR data available')),
                )
              : const AppScaffold(
                  body: Center(child: Text('No DVR data available')),
                );
        }

        // Initialize selected day if not set - prefer today's date
        if (_selectedDay.isEmpty || !seriesData!.containsKey(_selectedDay)) {
          _selectedDay = _findTodaysDate() ?? seriesData!.keys.first;
          _initializeDayKeys();
        }

        final content = Focus(
          focusNode: focusWrapper,
          onFocusChange: (value) {
            if (value) {
              dvrFocus.requestFocus();
            }
            setState(() {});
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              _buildDayList(),
              const SizedBox(width: 50),
              _buildDvrCardGrid(),
            ],
          ),
        );

        if (widget.isOverlay) {
          return Container(
            color: Colors.black.withOpacity(0.95),
            child: content,
          );
        }

        return AppScaffold(
          hasNavbar: false,
          body: content,
        );
      },
    );
  }

  Widget _buildDayList() {
    return Focus(
      focusNode: dvrFocus,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: SizedBox(
        width: 150,
        height: MediaQuery.sizeOf(context).height - 40,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: seriesData!.keys.length + 1,
          itemBuilder: (context, index) {
            if (index == seriesData!.keys.length) {
              return const SizedBox(height: 100);
            }
            final key = seriesData!.keys.elementAt(index);
            final isSelected = index == _currentPage && dvrFocus.hasFocus;

            return Container(
              key: _dayKeys[index],
              height: 60,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: isSelected ? context.uiColors.onSurface : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    key.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyles.bodyMediumBold.copyWith(
                      color: _selectedDay == key ? context.uiColors.primary : null,
                    ),
                  ),
                  if (_isToday(key))
                    Text(
                      'TODAY',
                      textAlign: TextAlign.center,
                      style: TextStyles.bodyMediumBold.copyWith(
                        color: _selectedDay == key ? context.uiColors.primary : null,
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

  Widget _buildDvrCardGrid() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      width: 700,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
            child: child,
          );
        },
        child: DvrCardGrid(
          key: ValueKey(_selectedDay),
          dvrFocus: dvrFocus,
          controller: _containerController,
          selectedDay: _selectedDay,
          seriesData: seriesData!,
          cardContainerFocus: cardContainerFocus,
          contentCubit: context.read<ContentCubit>(),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _currentPage = (_currentPage + 1) % seriesData!.keys.length;
          _ensureDayVisible();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        cardContainerFocus.requestFocus();
        setState(() {});
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _currentPage = (_currentPage - 1 + seriesData!.keys.length) % seriesData!.keys.length;
          _ensureDayVisible();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.select) {
        setState(() {
          _selectedDay = seriesData!.keys.elementAt(_currentPage);
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.goBack) {
        if (widget.isOverlay && widget.onClose != null) {
          widget.onClose!();
        } else {
          context.pop();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
