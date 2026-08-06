import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_kit/ui_kit.dart';

/// One entry in the bottom bar.
typedef FndtvNavItem = ({IconData icon, String label});

class FNDTVBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Supplied by the caller rather than hardcoded here: the Radio tab is
  /// dropped for languages that have no radio, which shifts every index after
  /// it.
  final List<FndtvNavItem> items;

  const FNDTVBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 64 + bottomPadding,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          top: BorderSide(width: 0.5, color: colors.border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              _NavItem(
                icon: items[i].icon,
                label: items[i].label,
                isActive: currentIndex == i,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    // Inactive: muted grey, Active: brand red (badgeNowText)
    final itemColor = isActive ? colors.badgeNowText : colors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator line (light blue)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 2,
              width: 24,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isActive ? colors.badgeNowText : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                size: 26,
                color: itemColor,
              ),
            ),
            const SizedBox(height: 4),
            // Label — kept to a single line and shrunk to fit so a long label
            // (e.g. FR "À la demande") doesn't wrap and misalign the row.
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: itemColor,
                    letterSpacing: 0.8,
                  ),
                  child: Text(label, maxLines: 1, softWrap: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
