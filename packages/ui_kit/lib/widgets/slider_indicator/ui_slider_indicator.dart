import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

/// Ui Slider indicator (left,right) fades if next not available
/// For pageView mostly
class UiSliderIndicator extends StatefulWidget {
  const UiSliderIndicator({
    super.key,
    required this.pageController,
    required this.sliderCount,
    required this.buttonFocus,
  });

  final PageController pageController;
  final int sliderCount;
  final FocusNode buttonFocus;

  @override
  State<UiSliderIndicator> createState() => UiSliderIndicatorState();
}

class UiSliderIndicatorState extends State<UiSliderIndicator> {
  Color _arrowLeftColor = AppColors.greyscale[500]!;

  // TODO: if we fetch sliders from backend check if the length is more than 1
  late Color _arrowRightColor = context.uiColors.primary;

  @override
  void initState() {
    final PageController controller = widget.pageController;

    controller.addListener(() {
      if (!controller.hasClients) return;

      if (controller.page == null) return;

      if (controller.page != controller.page!.toInt()) return;

      _arrowLeftColor = _getPreviousButtonColor();
      _arrowRightColor = _getNextButtonColor();

      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FocusWrapper(
        focusNodeCount: 2,
        focusNode: FocusNode(),
        focusActionMap: {
          LogicalKeyboardKey.arrowRight: (context, focusNodes) =>
              focusNodes.shiftFocusDown(context, focusNodes),
          LogicalKeyboardKey.arrowDown: (context, focusNodes) {
            widget.buttonFocus.requestFocus();
          }
        },
        build: (context, focusNodes) {
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SliderButton(
                  focusNode: focusNodes[0],
                  onPressed: _onPreviousPressed,
                  icon: Assets.arrowLeftCircle,
                  color: _arrowLeftColor,
                ),
                _SliderButton(
                    focusNode: focusNodes[1],
                    onPressed: _onNextPressed,
                    icon: Assets.arrowRightCircle,
                    color: _arrowRightColor),
              ]);
        });
  }

  void _onPreviousPressed() {
    widget.pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNextPressed() {
    widget.pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Color _getPreviousButtonColor() {
    final int currentPage = widget.pageController.page!.toInt();

    return currentPage == 0
        ? AppColors.greyscale[500]!
        : context.uiColors.primary;
  }

  Color _getNextButtonColor() {
    final int currentPage = widget.pageController.page!.toInt();
    return widget.sliderCount - 1 == currentPage
        ? AppColors.greyscale[500]!
        : context.uiColors.primary;
  }
}

class _SliderButton extends StatelessWidget {
  const _SliderButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.focusNode,
  });

  final VoidCallback onPressed;
  final Color color;
  final String icon;
  final FocusNode focusNode;
  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.transparent,
      child: InkWell(
        focusNode: focusNode,
        borderRadius: const BorderRadius.all(
          Radius.circular(100),
        ),
        onTap: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          switchInCurve: Curves.ease,
          switchOutCurve: Curves.ease,
          child: AppIcon(
            key: ValueKey<Color>(color),
            icon,
            color: color,
          ),
        ),
      ),
    );
  }
}
