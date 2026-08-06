import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/core/services/connectivity_observer.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';

enum NetworkJoinPhase { idle, connecting, failed }

class NetworkState extends Equatable {
  final bool online;

  /// Whether this box can actually manage Wi-Fi (device-owner OR root). When
  /// false the page degrades to status-only display (spec: error handling).
  final bool canManage;
  final bool wifiEnabled;
  final String? ssid;
  final String? ip;
  final bool ethernetLinked;
  final String? ethernetIp;
  final List<WifiNetwork> networks;
  final bool scanning;
  final NetworkJoinPhase joinPhase;
  final String? joiningSsid;
  final bool overlaySuppressed;

  const NetworkState({
    this.online = true,
    this.canManage = false,
    this.wifiEnabled = false,
    this.ssid,
    this.ip,
    this.ethernetLinked = false,
    this.ethernetIp,
    this.networks = const [],
    this.scanning = false,
    this.joinPhase = NetworkJoinPhase.idle,
    this.joiningSsid,
    this.overlaySuppressed = false,
  });

  NetworkState copyWith({
    bool? online,
    bool? canManage,
    bool? wifiEnabled,
    String? Function()? ssid,
    String? Function()? ip,
    bool? ethernetLinked,
    String? Function()? ethernetIp,
    List<WifiNetwork>? networks,
    bool? scanning,
    NetworkJoinPhase? joinPhase,
    String? Function()? joiningSsid,
    bool? overlaySuppressed,
  }) =>
      NetworkState(
        online: online ?? this.online,
        canManage: canManage ?? this.canManage,
        wifiEnabled: wifiEnabled ?? this.wifiEnabled,
        ssid: ssid != null ? ssid() : this.ssid,
        ip: ip != null ? ip() : this.ip,
        ethernetLinked: ethernetLinked ?? this.ethernetLinked,
        ethernetIp: ethernetIp != null ? ethernetIp() : this.ethernetIp,
        networks: networks ?? this.networks,
        scanning: scanning ?? this.scanning,
        joinPhase: joinPhase ?? this.joinPhase,
        joiningSsid: joiningSsid != null ? joiningSsid() : this.joiningSsid,
        overlaySuppressed: overlaySuppressed ?? this.overlaySuppressed,
      );

  @override
  List<Object?> get props => [
        online, canManage, wifiEnabled, ssid, ip, ethernetLinked, ethernetIp,
        networks, scanning, joinPhase, joiningSsid, overlaySuppressed,
      ];
}

/// Drives the Network page, the global identity badge and the offline overlay.
class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit({
    required StbNetworkService service,
    required ConnectivityObserver observer,
    Future<bool> Function()? checkManageable,
    this.joinPollInterval = const Duration(seconds: 2),
    this.joinTimeout = const Duration(seconds: 20),
  })  : _service = service,
        _observer = observer,
        _checkManageable = checkManageable,
        super(const NetworkState()) {
    _checkManageable?.call().then((ok) {
      if (!isClosed) emit(state.copyWith(canManage: ok));
    });
    _sub = _observer.onlineStream.listen((online) {
      emit(state.copyWith(online: online));
      refreshStatus();
    });
  }

  final StbNetworkService _service;
  final ConnectivityObserver _observer;
  final Future<bool> Function()? _checkManageable;
  final Duration joinPollInterval;
  final Duration joinTimeout;
  late final StreamSubscription<bool> _sub;

  Future<void> refreshStatus() async {
    final s = await _service.status();
    if (isClosed) return;
    emit(state.copyWith(
      wifiEnabled: s.wifiEnabled,
      ssid: () => s.ssid,
      ip: () => s.wifiIp,
      ethernetLinked: s.ethernetLinked,
      ethernetIp: () => s.ethernetIp,
    ));
  }

  /// Scans for networks. [retries] re-scans when the first pass comes back
  /// empty: enabling the radio doesn't make results available immediately —
  /// the supplicant needs a moment to come up — so a scan fired right after
  /// switching to Wi-Fi would otherwise show "no networks found".
  Future<void> scan({int retries = 0, Duration retryDelay = const Duration(seconds: 2)}) async {
    emit(state.copyWith(scanning: true));
    var networks = await _service.scan();
    var left = retries;
    while (networks.isEmpty && left > 0) {
      await Future<void>.delayed(retryDelay);
      if (isClosed) return;
      networks = await _service.scan();
      left--;
    }
    if (isClosed) return;
    emit(state.copyWith(scanning: false, networks: networks));
  }

  /// Initiates a join, then polls status until [ssid] is connected or
  /// [joinTimeout] elapses (wrong password only surfaces as a timeout).
  /// [security] (`open`/`wpa2`/`wpa3`) is forwarded so WPA3 uses SAE.
  Future<void> join(String ssid, {String? password, String? security}) async {
    emit(state.copyWith(joinPhase: NetworkJoinPhase.connecting, joiningSsid: () => ssid));
    final initiated = await _service.connect(ssid, password: password, security: security);
    if (isClosed) return;
    if (!initiated) {
      emit(state.copyWith(joinPhase: NetworkJoinPhase.failed));
      return;
    }
    final deadline = DateTime.now().add(joinTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(joinPollInterval);
      if (isClosed) return;
      final s = await _service.status();
      if (isClosed) return;
      if (s.ssid == ssid && (s.wifiIp?.isNotEmpty ?? false)) {
        emit(state.copyWith(
          joinPhase: NetworkJoinPhase.idle,
          joiningSsid: () => null,
          wifiEnabled: s.wifiEnabled,
          ssid: () => s.ssid,
          ip: () => s.wifiIp,
        ));
        await _observer.recheck();
        return;
      }
    }
    if (isClosed) return;
    emit(state.copyWith(joinPhase: NetworkJoinPhase.failed));
  }

  void clearJoinError() =>
      emit(state.copyWith(joinPhase: NetworkJoinPhase.idle, joiningSsid: () => null));

  /// Wired ⇄ Wi-Fi switch: "wired" = Wi-Fi off (Ethernet takes over).
  ///
  /// Switching TO Wi-Fi also (re)scans, so the user immediately sees the
  /// available networks to pick from — the radio was off until now, so the
  /// list was necessarily empty.
  Future<void> setUseWifi(bool useWifi) async {
    await _service.setWifiEnabled(useWifi);
    if (isClosed) return;
    await refreshStatus();
    if (isClosed) return;
    await _observer.recheck();
    if (isClosed) return;
    if (useWifi) await scan(retries: 3);
  }

  /// Boot-time safety net: if there is no Ethernet carrier (cable unplugged)
  /// and the Wi-Fi radio is off, the box has no way back online — Android
  /// persists the radio state across reboots, so a box last left in "wired"
  /// mode comes up stranded, still waiting on a cable that isn't there.
  /// Turning the radio back on lets it re-associate with a saved network.
  ///
  /// Returns true when it had to intervene.
  Future<bool> ensureBootConnectivity() async {
    await refreshStatus();
    if (isClosed) return false;
    if (state.ethernetLinked || state.wifiEnabled) return false;
    await _service.setWifiEnabled(true);
    if (isClosed) return false;
    await refreshStatus();
    if (isClosed) return false;
    await _observer.recheck();
    return true;
  }

  void suppressOverlay(bool suppressed) =>
      emit(state.copyWith(overlaySuppressed: suppressed));

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
