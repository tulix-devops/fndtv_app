import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/core/services/app_route_tracker.dart';
import 'package:fndtv/src/index.dart' show VideoPlayerPage;
import 'package:google_fonts/google_fonts.dart';

/// A labelled identity block in the bottom-right corner, on every screen:
/// `Serial number: … / MAC address: …`. Support asks the customer to read it
/// off the corner, so it's a clear white-on-dark card, not a dim overlay.
/// Hidden over fullscreen video. Labels are localized (en/es/fr).
class TvIdentityBadge extends StatelessWidget {
  const TvIdentityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppRouteTracker.currentRoute,
      builder: (context, route, _) {
        if (route == VideoPlayerPage.path) return const SizedBox.shrink();
        return BlocBuilder<DeviceIdentityCubit, DeviceIdentityState>(
          builder: (context, id) {
            if (!id.loaded || (id.mac.isEmpty && id.serial.isEmpty)) {
              return const SizedBox.shrink();
            }
            final l = context.l;
            return Positioned(
              right: 24,
              bottom: 20,
              // Wrapped in a transparent Material: the badge is mounted in the
              // MaterialApp.builder Stack, OUTSIDE any Scaffold/Material, so
              // text would otherwise render with Flutter's yellow "no default
              // text style" debug underline.
              child: Material(
                type: MaterialType.transparency,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (id.serial.isNotEmpty)
                          _line(l.networkDeviceSerial, id.serial),
                        if (id.mac.isNotEmpty) ...[
                          if (id.serial.isNotEmpty) const SizedBox(height: 3),
                          _line(l.networkDeviceMac, id.mac),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _line(String label, String value) => RichText(
        text: TextSpan(
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      );
}
