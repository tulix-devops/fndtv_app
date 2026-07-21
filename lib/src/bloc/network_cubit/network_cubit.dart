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
    this.canManage = true,
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
    emit(state.copyWith(
      wifiEnabled: s.wifiEnabled,
      ssid: () => s.ssid,
      ip: () => s.wifiIp,
      ethernetLinked: s.ethernetLinked,
      ethernetIp: () => s.ethernetIp,
    ));
  }

  Future<void> scan() async {
    emit(state.copyWith(scanning: true));
    final networks = await _service.scan();
    emit(state.copyWith(scanning: false, networks: networks));
  }

  /// Initiates a join, then polls status until [ssid] is connected or
  /// [joinTimeout] elapses (wrong password only surfaces as a timeout).
  Future<void> join(String ssid, {String? password}) async {
    emit(state.copyWith(joinPhase: NetworkJoinPhase.connecting, joiningSsid: () => ssid));
    final initiated = await _service.connect(ssid, password: password);
    if (!initiated) {
      emit(state.copyWith(joinPhase: NetworkJoinPhase.failed));
      return;
    }
    final deadline = DateTime.now().add(joinTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(joinPollInterval);
      final s = await _service.status();
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
    emit(state.copyWith(joinPhase: NetworkJoinPhase.failed));
  }

  void clearJoinError() =>
      emit(state.copyWith(joinPhase: NetworkJoinPhase.idle, joiningSsid: () => null));

  /// Wired ⇄ Wi-Fi switch: "wired" = Wi-Fi off (Ethernet takes over).
  Future<void> setUseWifi(bool useWifi) async {
    await _service.setWifiEnabled(useWifi);
    await refreshStatus();
    await _observer.recheck();
  }

  void suppressOverlay(bool suppressed) =>
      emit(state.copyWith(overlaySuppressed: suppressed));

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
