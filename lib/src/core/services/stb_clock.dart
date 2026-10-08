import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:local_storage/local_storage.dart';

/// Local-storage keys for the resolved zone. Persisted so a box that is offline
/// at boot still renders the right times from the first frame, using what it
/// learned last time, instead of waiting on a lookup that may never land.
const String kStbTimezoneIdKey = 'stb_timezone_id';
const String kStbTimezoneOffsetKey = 'stb_timezone_offset_seconds';

/// The offset the app renders schedule times through.
///
/// WHY THIS EXISTS. Setting the box's system timezone needs root
/// (`setprop persist.sys.timezone`), and on boxes where `su` is refused it stays
/// wrong permanently. NTP still corrects the absolute clock, so the box knows
/// *when* it is but not *where* — and every `DateTime.toLocal()` then lands an
/// hour or two out. That is the EPG showing the wrong programme.
///
/// So the app stops trusting the system zone. It resolves the real UTC offset
/// from geolocation, persists it, and converts through it. A box we have no
/// privileges over still shows the right times.
///
/// Falls back to `toLocal()` whenever no offset has ever been resolved, which is
/// the previous behaviour and correct on any box whose zone is actually right.
class StbClock {
  StbClock({
    StbSystemService? system,
    List<Duration> retrySchedule = kStbClockRetrySchedule,
    Duration refreshInterval = const Duration(hours: 6),
    Future<void> Function(Duration)? delay,
    bool? enabled,
  })  : _system = system ?? StbSystemService(),
        _retrySchedule = retrySchedule,
        _refreshInterval = refreshInterval,
        _delay = delay ?? Future<void>.delayed,
        _enabled = enabled ?? StbSystemService.isStb;

  static final StbClock instance = StbClock();

  final StbSystemService _system;
  final List<Duration> _retrySchedule;
  final Duration _refreshInterval;
  final Future<void> Function(Duration) _delay;

  /// Whether this build is the set-top box. Injected rather than read inline so
  /// the retry and conversion logic is testable — the flavor gate is not what
  /// needs covering, the offset maths is.
  final bool _enabled;

  Duration? _offset;
  String? _zoneId;
  Timer? _refreshTimer;
  bool _running = false;
  bool _disposed = false;

  /// Resolved zone id (e.g. `Europe/Paris`), or null if never resolved.
  String? get zoneId => _zoneId;

  /// Resolved UTC offset, or null if never resolved.
  Duration? get offset => _offset;

  /// True once a real offset is known, from storage or the network.
  bool get isResolved => _offset != null;

  /// Converts [time] into the box's real local time.
  ///
  /// Use everywhere a schedule timestamp is displayed, in place of `toLocal()`.
  /// Falls back to `toLocal()` until an offset is known, so this is never worse
  /// than the behaviour it replaces.
  DateTime toBoxLocal(DateTime time) {
    final off = _offset;
    if (off == null) return time.toLocal();
    return time.toUtc().add(off);
  }

  /// "Now" in the box's real local time.
  DateTime now() => toBoxLocal(DateTime.now());

  /// Loads the persisted offset. Call before the first frame — it makes the
  /// first render correct on a box that is still offline.
  Future<void> load(LocalStorage storage) async {
    try {
      final id = await storage.get<String>(kStbTimezoneIdKey);
      final seconds = await storage.get<int>(kStbTimezoneOffsetKey);
      if (seconds != null) {
        _offset = Duration(seconds: seconds);
        _zoneId = id;
        logger.i('[STB] Clock restored: $id (${seconds}s)');
      }
    } catch (e) {
      logger.w('[STB] Clock restore failed: $e');
    }
  }

  /// Resolves the zone from the network, retrying until it lands, then keeps it
  /// fresh.
  ///
  /// The retries are the point. FNDTV starts before the box has a network — a
  /// box in the field resolved DHCP eleven seconds AFTER the app had already
  /// tried all three geolocation providers and given up, and nothing re-fired
  /// it, so the zone stayed wrong until the next reboot.
  ///
  /// The periodic refresh exists for daylight saving: the offset we store is the
  /// one in force when we asked, so a box left running across a DST change would
  /// otherwise stay an hour out until someone rebooted it.
  Future<void> start(LocalStorage storage) async {
    if (!_enabled || _disposed || _running) return;
    _running = true;
    try {
      for (final gap in _retrySchedule) {
        if (_disposed) return;
        if (gap > Duration.zero) await _delay(gap);
        if (_disposed) return;
        if (await _resolveOnce(storage)) break;
      }
    } finally {
      _running = false;
    }
    _scheduleRefresh(storage);
  }

  Future<bool> _resolveOnce(LocalStorage storage) async {
    final zone = await _system.syncTimezone();
    if (zone == null) return false;

    final seconds = zone.offsetSeconds;
    _offset = Duration(seconds: seconds);
    _zoneId = zone.id;
    logger.i('[STB] Clock resolved: ${zone.id} (${seconds}s, '
        'appliedToSystem=${zone.applied})');

    try {
      await storage.store<String>(kStbTimezoneIdKey, zone.id);
      await storage.store<int>(kStbTimezoneOffsetKey, seconds);
    } catch (e) {
      // Cache is an optimisation — the value is already live in memory.
      logger.w('[STB] Clock persist failed: $e');
    }
    return true;
  }

  void _scheduleRefresh(LocalStorage storage) {
    if (_disposed || _refreshInterval <= Duration.zero) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      if (_disposed) return;
      await _resolveOnce(storage);
    });
  }

  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}

/// Gaps between zone-resolution attempts, each measured from the previous one
/// (so: 0s, 5s, 15s, 45s, 2m, 5m after launch).
///
/// Front-loaded because Ethernet usually comes up within ~15s of boot, and
/// stretched at the tail because Wi-Fi association, a captive portal or a slow
/// uplink can take minutes — and a box that never resolves shows the wrong EPG
/// all day.
const List<Duration> kStbClockRetrySchedule = <Duration>[
  Duration.zero,
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 30),
  Duration(minutes: 1),
  Duration(minutes: 3),
];
