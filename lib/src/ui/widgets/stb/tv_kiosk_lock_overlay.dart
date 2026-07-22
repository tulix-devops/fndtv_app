import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/core/services/kiosk_lock_controller.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen blocker shown while the box is kiosk-locked by an MDM
/// `KIOSK_LOCK` command (e.g. a suspended account). Unlike the offline overlay
/// there is no CTA — the box can only be released by a `KIOSK_UNLOCK` command.
/// It traps focus and swallows the Back button so the user can't escape it,
/// and shows the device identity so phone support can act.
class TvKioskLockOverlay extends StatelessWidget {
  const TvKioskLockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<KioskLockController>();
    return ValueListenableBuilder<bool>(
      valueListenable: controller.locked,
      builder: (context, locked, _) {
        if (!locked) return const SizedBox.shrink();
        final id = context.watch<DeviceIdentityCubit>().state;
        final l = context.l;
        return Positioned.fill(
          child: PopScope(
            canPop: false,
            child: Material(
              color: const Color(0xF60A0D12),
              child: FocusScope(
                autofocus: true,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          color: Colors.white70, size: 64),
                      const SizedBox(height: 20),
                      Text(
                        l.kioskLockTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.kioskLockMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                            color: Colors.white60, fontSize: 15),
                      ),
                      if (id.mac.isNotEmpty || id.serial.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          [
                            if (id.serial.isNotEmpty) 'SN ${id.serial}',
                            if (id.mac.isNotEmpty) 'MAC ${id.mac}',
                          ].join('  ·  '),
                          style: GoogleFonts.sora(
                              color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
