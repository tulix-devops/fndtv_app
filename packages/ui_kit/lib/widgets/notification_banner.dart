import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class NotificationBanner extends StatefulWidget {
  const NotificationBanner(
    this.message,
    this.type, {
    super.key,
    required this.onDismissed,
  });

  final String? message;
  final NotificationType type;
  final VoidCallback onDismissed;
  @override
  State<StatefulWidget> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  @override
  Widget build(BuildContext context) {
    const EdgeInsets padding = EdgeInsets.fromLTRB(16.0, 16, 16.0, 0);
    return SafeArea(
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.up,
        onDismissed: (_) {
          widget.onDismissed();
        },
        child: Padding(
          padding: padding,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 56,
              minWidth: double.infinity,
            ),
            decoration: ShapeDecoration(
              color: Color.alphaBlend(
                notificationColor.withOpacity(0.2),
                Colors.white,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
            ),
            child: Padding(
              padding: Paddings.all16,
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppIcon(
                      Assets.alertCircle,
                      color: notificationColor,
                    ),
                    Margins.horizontal10,
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.message ?? '',
                          style: TextStyles.bodySmallRegular.copyWith(
                            color: notificationColor,
                          ),
                          overflow: TextOverflow.visible,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get notificationColor {
    switch (widget.type) {
      case NotificationType.error:
        return context.uiColors.error;
      case NotificationType.success:
        return context.uiColors.success;

      case NotificationType.warning:
        return context.uiColors.warning;

      case NotificationType.info:
        return context.uiColors.info;
    }
  }
}
