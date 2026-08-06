import 'dart:async';

import 'package:commons/commons.dart' show APIList;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Watches real internet reachability: connectivity_plus tells us when an
/// interface changes, but interface-up ≠ internet — so every change (and a
/// 30 s ticker while offline) is confirmed with a cheap probe against the box
/// backend's `/health`. Emits deduplicated online/offline transitions.
class ConnectivityObserver {
  ConnectivityObserver({
    Stream<List<ConnectivityResult>>? changes,
    Future<bool> Function()? probe,
  })  : _probe = probe ?? _defaultProbe {
    _sub = (changes ?? Connectivity().onConnectivityChanged).listen(_onChange);
  }

  final Future<bool> Function() _probe;
  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  Timer? _offlineTicker;
  int _offlineProbes = 0;
  bool _online = true;
  bool _emittedOnce = false;
  bool _disposed = false;

  /// Bumped at the start of every change/recheck probe so a stale (slower)
  /// probe that resolves after a newer one can't clobber the newer result.
  int _generation = 0;

  bool get isOnline => _online;
  Stream<bool> get onlineStream => _controller.stream;

  Future<void> _onChange(List<ConnectivityResult> results) async {
    final gen = ++_generation;
    final hasInterface =
        results.any((r) => r != ConnectivityResult.none);
    final online = hasInterface && await _probe();
    if (gen != _generation) return; // superseded by a newer event
    _set(online);
  }

  /// While offline we re-probe on a timer. Right after a reboot Wi-Fi can take
  /// 5–15 s to associate (Ethernet is instant), so a flat 30 s poll leaves the
  /// box looking stuck on a wired link that isn't there for far longer than it
  /// actually is. Probe quickly at first, then back off to save battery/radio.
  static const Duration _fastProbeInterval = Duration(seconds: 5);
  static const Duration _slowProbeInterval = Duration(seconds: 30);
  static const int _fastProbeCount = 12; // ~1 min of fast probes

  void _set(bool online) {
    if (_disposed) return;
    final changed = online != _online || !_emittedOnce;
    _online = online;
    _emittedOnce = true;
    if (changed && !_controller.isClosed) _controller.add(online);
    if (!online) {
      if (_offlineTicker == null) {
        _offlineProbes = 0;
        _scheduleOfflineProbe();
      }
    } else {
      _offlineTicker?.cancel();
      _offlineTicker = null;
      _offlineProbes = 0;
    }
  }

  void _scheduleOfflineProbe() {
    _offlineTicker?.cancel();
    final delay =
        _offlineProbes < _fastProbeCount ? _fastProbeInterval : _slowProbeInterval;
    _offlineTicker = Timer(delay, () async {
      if (_disposed) return;
      _offlineProbes++;
      if (await _probe()) {
        _set(true);
      } else if (!_online && !_disposed) {
        _scheduleOfflineProbe();
      }
    });
  }

  /// Manual re-check (e.g. after a Wi-Fi join) — probes and updates state.
  Future<bool> recheck() async {
    final gen = ++_generation;
    final online = await _probe();
    if (gen != _generation) return _online; // superseded by a newer event
    _set(online);
    return online;
  }

  static Future<bool> _defaultProbe() async {
    try {
      final res = await http
          .get(Uri.parse(APIList.boxHealth))
          .timeout(const Duration(seconds: 5));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _offlineTicker?.cancel();
    _offlineTicker = null;
    await _sub.cancel();
    if (!_controller.isClosed) await _controller.close();
  }
}
