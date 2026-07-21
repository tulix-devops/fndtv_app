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
  bool _online = true;
  bool _emittedOnce = false;

  bool get isOnline => _online;
  Stream<bool> get onlineStream => _controller.stream;

  Future<void> _onChange(List<ConnectivityResult> results) async {
    final hasInterface =
        results.any((r) => r != ConnectivityResult.none);
    final online = hasInterface && await _probe();
    _set(online);
  }

  void _set(bool online) {
    final changed = online != _online || !_emittedOnce;
    _online = online;
    _emittedOnce = true;
    if (changed) _controller.add(online);
    if (!online) {
      _offlineTicker ??= Timer.periodic(const Duration(seconds: 30), (_) async {
        if (await _probe()) _set(true);
      });
    } else {
      _offlineTicker?.cancel();
      _offlineTicker = null;
    }
  }

  /// Manual re-check (e.g. after a Wi-Fi join) — probes and updates state.
  Future<bool> recheck() async {
    final online = await _probe();
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
    _offlineTicker?.cancel();
    await _sub.cancel();
    await _controller.close();
  }
}
