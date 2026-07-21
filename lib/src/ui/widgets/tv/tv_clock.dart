import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// A small local-time clock shown top-right on the TV UI. Display-only — it is
/// intentionally NOT focusable so it never steals D-pad focus from the content
/// grid. (Changing the time is exposed elsewhere via the native
/// `openDateSettings` channel method.)
class TvClock extends StatefulWidget {
  const TvClock({super.key});

  @override
  State<TvClock> createState() => _TvClockState();
}

class _TvClockState extends State<TvClock> {
  Timer? _timer;
  late String _time;

  @override
  void initState() {
    super.initState();
    _time = _now();
    // Tick every 10s — cheap and keeps the minute display current.
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final t = _now();
      if (t != _time && mounted) setState(() => _time = t);
    });
  }

  String _now() => DateFormat('HH:mm').format(DateTime.now());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 7),
            Text(
              _time,
              style: GoogleFonts.sora(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
