import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/core/services/app_route_tracker.dart';
import 'package:fndtv/src/index.dart' show VideoPlayerPage;
import 'package:google_fonts/google_fonts.dart';

/// One dim line under the TV clock, on every screen: `MAC … · SN …`.
/// Support asks the customer to read the top-right corner — that's this.
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
            final parts = <String>[
              if (id.mac.isNotEmpty) 'MAC ${id.mac}',
              if (id.serial.isNotEmpty) 'SN ${id.serial}',
            ];
            return Positioned(
              top: 48,
              right: 24,
              // Wrapped in a transparent Material: the badge is mounted in the
              // MaterialApp.builder Stack, OUTSIDE any Scaffold/Material, so a
              // bare Text renders with Flutter's yellow "no default text style"
              // debug underline. Material supplies a proper DefaultTextStyle.
              child: Material(
                type: MaterialType.transparency,
                child: IgnorePointer(
                  child: Text(
                    parts.join(' · '),
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
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
}
