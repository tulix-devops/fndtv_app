import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart' show kTvBg, kTvAccent;
import 'package:google_fonts/google_fonts.dart';

/// Full-screen Network page (TV/STB): connection + ethernet + identity cards
/// on the left, scannable Wi-Fi list on the right. Wired ⇄ Wi-Fi switch with
/// a no-cable warning. Suppresses the global offline overlay while open.
class TvNetworkPage extends StatefulWidget {
  const TvNetworkPage({super.key});

  @override
  State<TvNetworkPage> createState() => _TvNetworkPageState();
}

class _TvNetworkPageState extends State<TvNetworkPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<NetworkCubit>();
    cubit.suppressOverlay(true);
    cubit.refreshStatus();
    cubit.scan();
  }

  @override
  void dispose() {
    context.read<NetworkCubit>().suppressOverlay(false);
    super.dispose();
  }

  Future<void> _onNetworkSelected(WifiNetwork network) async {
    final cubit = context.read<NetworkCubit>();
    if (!network.secured) {
      await cubit.join(network.ssid);
      return;
    }
    final password = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => _PasswordPage(ssid: network.ssid),
      ),
    );
    if (password != null && password.isNotEmpty && mounted) {
      await cubit.join(network.ssid, password: password);
    }
  }

  Future<void> _onModeChanged(bool useWifi) async {
    final cubit = context.read<NetworkCubit>();
    if (!useWifi && !cubit.state.ethernetLinked) {
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const _WiredWarnPage()),
      );
      if (confirmed != true) return;
    }
    if (mounted) await cubit.setUseWifi(useWifi);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      backgroundColor: kTvBg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(48, 36, 48, 24),
        child: BlocBuilder<NetworkCubit, NetworkState>(
          builder: (context, net) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_rounded, color: kTvAccent, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      l.networkTitle,
                      style: GoogleFonts.sora(
                          fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: _leftColumn(context, net)),
                      const SizedBox(width: 28),
                      Expanded(child: _networksList(context, net)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _leftColumn(BuildContext context, NetworkState net) {
    final l = context.l;
    final id = context.watch<DeviceIdentityCubit>().state;
    return ListView(
      children: [
        _Card(
          title: l.networkConnectionCard,
          children: [
            // Degrade to status-only when the box can't manage Wi-Fi
            // (no device-owner and no root).
            if (net.canManage) ...[
              Row(
                children: [
                  _ModeButton(
                    label: l.networkModeWifi,
                    active: net.wifiEnabled,
                    autofocus: true,
                    onTap: () => _onModeChanged(true),
                  ),
                  const SizedBox(width: 10),
                  _ModeButton(
                    label: l.networkModeWired,
                    active: !net.wifiEnabled,
                    onTap: () => _onModeChanged(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            _kv(l.networkStatusLabel,
                net.online ? l.networkStatusConnected : l.networkStatusOffline,
                valueColor: net.online ? const Color(0xFF3BB273) : Colors.white38),
            if (net.ssid != null) _kv(l.networkSsid, net.ssid!),
            if (net.ip != null) _kv(l.networkIp, net.ip!),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          title: l.networkEthernetCard,
          children: [
            _kv(
              l.networkEthernetCard,
              net.ethernetLinked ? l.networkEthernetLinked : l.networkEthernetNoCable,
              valueColor:
                  net.ethernetLinked ? const Color(0xFF3BB273) : Colors.white38,
            ),
            if (net.ethernetIp != null) _kv(l.networkIp, net.ethernetIp!),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          title: l.networkDeviceCard,
          children: [
            if (id.mac.isNotEmpty) _kv(l.networkDeviceMac, id.mac),
            if (id.serial.isNotEmpty) _kv(l.networkDeviceSerial, id.serial),
            if (id.deviceId != null) _kv(l.networkDeviceId, id.deviceId!),
            if (id.version.isNotEmpty) _kv(l.networkDeviceVersion, 'v${id.version}'),
          ],
        ),
      ],
    );
  }

  Widget _networksList(BuildContext context, NetworkState net) {
    final l = context.l;
    return _Card(
      title: l.networkAvailable,
      trailing: _ModeButton(
        label: net.scanning ? l.networkScanning : l.networkScan,
        active: false,
        onTap: net.scanning ? null : () => context.read<NetworkCubit>().scan(),
      ),
      children: [
        if (net.joinPhase == NetworkJoinPhase.failed) ...[
          Text(l.networkJoinFailed,
              style: GoogleFonts.sora(color: kTvAccent, fontSize: 13)),
          const SizedBox(height: 8),
        ],
        if (net.networks.isEmpty && !net.scanning)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.networkNoneFound,
                style: GoogleFonts.sora(color: Colors.white38, fontSize: 14)),
          ),
        for (final n in net.networks)
          _NetworkRow(
            network: n,
            connected: n.ssid == net.ssid,
            connecting: net.joinPhase == NetworkJoinPhase.connecting &&
                net.joiningSsid == n.ssid,
            connectingLabel: l.networkConnecting,
            // Status-only when the box can't manage Wi-Fi.
            onTap: net.canManage ? () => _onNetworkSelected(n) : null,
          ),
      ],
    );
  }

  Widget _kv(String k, String v, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(k,
                  style: GoogleFonts.sora(color: Colors.white38, fontSize: 12)),
            ),
            Expanded(
              child: Text(v,
                  style: GoogleFonts.sora(
                      color: valueColor ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children, this.trailing});
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2130),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3348)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.sora(
                      color: const Color(0xFF8FA1C0),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Focusable red-outline button (same look as the Updates page buttons).
class _ModeButton extends StatefulWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    this.onTap,
    this.autofocus = false,
  });
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        autofocus: widget.autofocus,
        onFocusChange: (f) => setState(() => _focused = f),
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _focused
                ? kTvAccent
                : (widget.active
                    ? kTvAccent.withValues(alpha: 0.25)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kTvAccent, width: 1.2),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.sora(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _NetworkRow extends StatefulWidget {
  const _NetworkRow({
    required this.network,
    required this.connected,
    required this.connecting,
    required this.connectingLabel,
    required this.onTap,
  });
  final WifiNetwork network;
  final bool connected;
  final bool connecting;
  final String connectingLabel;
  final VoidCallback? onTap;

  @override
  State<_NetworkRow> createState() => _NetworkRowState();
}

class _NetworkRowState extends State<_NetworkRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.network;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onFocusChange: (f) => setState(() => _focused = f),
        borderRadius: BorderRadius.circular(8),
        onTap: widget.connecting ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _focused ? kTvAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                n.secured ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 14,
                color: _focused ? Colors.white : Colors.white38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  n.ssid,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                          widget.connected ? FontWeight.w800 : FontWeight.w500),
                ),
              ),
              if (widget.connecting)
                Text(widget.connectingLabel,
                    style: GoogleFonts.sora(color: Colors.white70, fontSize: 11))
              else if (widget.connected)
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF3BB273))
              else
                Icon(Icons.wifi_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.15 + 0.2 * n.level)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen password entry (own route → own focus scope, like the language
/// page). Relies on the system IME; pops with the entered password.
class _PasswordPage extends StatefulWidget {
  const _PasswordPage({required this.ssid});
  final String ssid;

  @override
  State<_PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<_PasswordPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      backgroundColor: kTvBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l.networkPasswordTitle} — ${widget.ssid}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                style: GoogleFonts.sora(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: l.networkPasswordHint,
                  hintStyle: GoogleFonts.sora(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A2130),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A3348)),
                  ),
                ),
                onSubmitted: (v) => Navigator.of(context).pop(v),
              ),
              const SizedBox(height: 22),
              _ModeButton(
                label: l.networkConnect,
                active: true,
                onTap: () => Navigator.of(context).pop(_controller.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirm switching to wired when no cable is detected.
class _WiredWarnPage extends StatelessWidget {
  const _WiredWarnPage();

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      backgroundColor: kTvBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: kTvAccent, size: 56),
              const SizedBox(height: 18),
              Text(l.networkWiredWarnTitle,
                  style: GoogleFonts.sora(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(l.networkWiredWarnBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeButton(
                    label: l.networkWiredWarnCancel,
                    active: false,
                    autofocus: true,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 14),
                  _ModeButton(
                    label: l.networkWiredWarnConfirm,
                    active: false,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
