import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class CategoryButton extends StatefulWidget {
  const CategoryButton({
    super.key,
    required this.selection,
    required this.title,
  });
  final String title;
  final ({bool isSelected, bool isHovering}) selection;

  @override
  State<CategoryButton> createState() => CategoryButtonState();
}

class CategoryButtonState extends State<CategoryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection.isSelected != oldWidget.selection.isSelected) {
      if (widget.selection.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  Color getCategoryColor() {
    if (widget.selection.isHovering) {
      return AppColors.greyscale[700]!;
    }

    if (widget.selection.isSelected) {
      return context.uiColors.primary;
    }

    return context.uiColors.primary;
  }

  Color getTextColor() {
    return context.uiColors.surface;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: getCategoryColor(),
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
          boxShadow: widget.selection.isSelected
              ? [
                  BoxShadow(
                    color: context.uiColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyles.bodyXLargeBold.copyWith(
                color: getTextColor(),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.title),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
