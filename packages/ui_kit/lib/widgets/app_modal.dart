import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class AppModal extends StatefulWidget {
  final String? icon;
  final List<Widget> children;
  final Color? imageColor;
  final Color? iconColor;
  final String title;
  final String label;
  final EdgeInsets? padding;

  const AppModal({
    super.key,
    required this.children,
    required this.title,
    required this.label,
    this.icon,
    this.iconColor,
    this.imageColor,
    this.padding,
  });

  @override
  State<AppModal> createState() => _AppModalState();
}

class _AppModalState extends State<AppModal> {
  BoxDecoration _decoration(BuildContext context) {
    return BoxDecoration(
      color: context.isDarkMode ? AppColors.dark2 : context.uiColors.onPrimary,
      borderRadius: const BorderRadius.all(
        Radius.circular(40.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(32.0, 40.0, 32.0, 32.0),
      backgroundColor: Colors.transparent,
      child: _ModalContent(
          decoration: _decoration(context),
          widget: widget,
          headLineStyle: TextStyles.h4.primary(context),
          labelStyle: TextStyles.bodyLarge.surface(context)),
    );
  }
}

class _ModalContent extends StatelessWidget {
  const _ModalContent({
    required BoxDecoration decoration,
    required this.widget,
    required TextStyle headLineStyle,
    required TextStyle labelStyle,
  })  : _decoration = decoration,
        _headLineStyle = headLineStyle,
        _labelStyle = labelStyle;

  final BoxDecoration _decoration;
  final AppModal widget;
  final TextStyle _headLineStyle;
  final TextStyle _labelStyle;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets contentPadding = EdgeInsets.fromLTRB(32, 40, 32, 32);

    return Container(
      decoration: _decoration,
      padding: contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AppIcon(
                Assets.modalImg,
                height: 150,
                color: widget.imageColor,
              ),
              Positioned.fill(
                child: Center(
                  child: AppIcon(
                    widget.icon ?? Assets.tick,
                    color: widget.iconColor ?? Colors.white,
                    height: 59,
                    width: 59,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Expanded(
          //   child: Text(
          //     widget.title,
          //     style: _headLineStyle,
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          Text(
            widget.title,
            style: _headLineStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.label,
            style: _labelStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (widget.children.isNotEmpty)
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [...widget.children],
            ),
        ],
      ),
    );
  }
}
