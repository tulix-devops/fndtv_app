import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/ui/app.dart' show appNavigatorKey;
import 'package:fndtv/src/ui/pages/network/tv_network_page.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen blocker while the box is offline. Shows the identity line (so
/// phone support works even with no internet) and one CTA into the Network
/// page. Suppressed while the Network page itself is open; auto-dismisses when
/// the observer reports online again.
class TvOfflineOverlay extends StatelessWidget {
  const TvOfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      buildWhen: (p, c) =>
          p.online != c.online || p.overlaySuppressed != c.overlaySuppressed,
      builder: (context, net) {
        if (net.online || net.overlaySuppressed) return const SizedBox.shrink();
        final id = context.watch<DeviceIdentityCubit>().state;
        final l = context.l;
        return Positioned.fill(
          child: Material(
            color: const Color(0xF20A0D12),
            child: FocusScope(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 64),
                  const SizedBox(height: 20),
                  Text(
                    l.offlineTitle,
                    style: GoogleFonts.sora(
                        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  if (id.mac.isNotEmpty || id.serial.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      [
                        if (id.mac.isNotEmpty) 'MAC ${id.mac}',
                        if (id.serial.isNotEmpty) 'SN ${id.serial}',
                      ].join(' · '),
                      style: GoogleFonts.sora(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _OfflineCta(
                    label: l.offlineCta,
                    onTap: () {
                      appNavigatorKey.currentState?.push(
                        MaterialPageRoute<void>(builder: (_) => const TvNetworkPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OfflineCta extends StatefulWidget {
  const _OfflineCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_OfflineCta> createState() => _OfflineCtaState();
}

class _OfflineCtaState extends State<_OfflineCta> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE0433D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        autofocus: true,
        onFocusChange: (f) => setState(() => _focused = f),
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          decoration: BoxDecoration(
            color: _focused ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent, width: 1.5),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.sora(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
