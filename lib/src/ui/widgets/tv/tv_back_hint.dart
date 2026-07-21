import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';

/// Non-interactive hint shown on TV content screens telling the viewer that the
/// Back (or Left) button opens the navigation menu.
class TvBackHint extends StatelessWidget {
  const TvBackHint({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_left_rounded,
                color: Colors.white70, size: 18),
            const SizedBox(width: 4),
            Text(
              context.l.navMenu,
              style: GoogleFonts.sora(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
