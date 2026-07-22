import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';

/// Top-right TV information block: the local-time clock, plus — on the set-top
/// box build — the device serial number on a second line. Combining them keeps
/// everything the user/support needs in ONE place. The MAC address and backend
/// device id are intentionally NOT here; they live in the Network page.
///
/// Display-only (not focusable) so it never steals D-pad focus from the grid.
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
    // STB only: the box serial, once the identity has loaded. Empty elsewhere,
    // so the block collapses back to a plain clock pill.
    final serial = StbSystemService.isStb
        ? context.select<DeviceIdentityCubit, String>(
            (c) => c.state.loaded ? c.state.serial : '')
        : '';
    final hasSerial = serial.isNotEmpty;

    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: hasSerial ? 9 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(hasSerial ? 14 : 20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            if (hasSerial) ...[
              const SizedBox(height: 7),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.sora(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                  children: [
                    TextSpan(
                      text: '${context.l.networkDeviceSerial}: ',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(text: serial),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
