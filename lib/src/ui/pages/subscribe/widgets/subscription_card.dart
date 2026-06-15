import 'package:commons/shared/extensions.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/ui/pages/pages.dart';
import 'package:ui_kit/ui_kit.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    const BorderRadius borderRadius = BorderRadius.all(Radius.circular(32));
    return InkWell(
      onTap: () {
        // context.pushNamed(SubscribePage.name);
      },
      borderRadius: borderRadius,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: context.uiColors.primary, width: 1),
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppIcon(Assets.crown, gradient: context.uiColors.primaryGradient),
            Margins.horizontal20,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Premium',
                    style: TextStyles.h4.copyWith(
                      color: context.uiColors.primary,
                    ),
                  ),
                  const Text(
                    'Enjoy watching Full-HD movies, without restrictions and without ads',
                    style: TextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            AppIcon(
              Assets.singleArrowRight,
              height: 24,
              gradient: context.uiColors.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }
}
