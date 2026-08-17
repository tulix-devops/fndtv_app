import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';

/// Gaps between kiosk-maintenance passes, each measured from the previous one
/// (so: 0s, 3s, 8s, 20s, 45s after launch).
///
/// FNDTV *is* the launcher, so it starts before the box has finished coming up:
/// the `su` daemon may not have granted yet and PackageManager is still
/// settling. A single pass at splash — what shipped — therefore did nothing at
/// all on a slow boot, and got no second chance until the next reboot. That is
/// why the takeover "sometimes" worked. Spreading the attempts across the first
/// minute costs nothing on a healthy box: pass one succeeds and the rest are
/// skipped.
const List<Duration> kStbKioskSchedule = <Duration>[
  Duration.zero,
  Duration(seconds: 3),
  Duration(seconds: 5),
  Duration(seconds: 12),
  Duration(seconds: 25),
];

/// Keeps FNDTV the home screen, and keeps it that way.
///
/// The native pass is best-effort by nature — it depends on root, on device
/// owner, and on firmware that may refuse to uninstall its own launcher. This
/// guard turns that into something with an outcome: it retries until the box
/// verifiably holds HOME, re-asserts when the user comes back into the app
/// (very often the moment they have just answered the "Use ___ as Home"
/// chooser), and logs loudly when it cannot get there so a box in that state is
/// diagnosable instead of silent.
class StbKioskGuard with WidgetsBindingObserver {
  StbKioskGuard({
    StbSystemService? system,
    List<Duration> schedule = kStbKioskSchedule,
    Duration resumeCooldown = const Duration(seconds: 30),
    Future<void> Function(Duration)? delay,
    bool? enabled,
  })  : _system = system ?? StbSystemService(),
        _schedule = schedule,
        _resumeCooldown = resumeCooldown,
        _delay = delay ?? Future<void>.delayed,
        _enabled = enabled ?? StbSystemService.isStb;

  /// Shared instance. Owned by the app rather than a page: the splash is
  /// replaced once boot finishes, and a guard disposed with it would stop
  /// watching for resumes — which is exactly when it is most useful.
  static final StbKioskGuard instance = StbKioskGuard();

  final StbSystemService _system;
  final List<Duration> _schedule;
  final Duration _resumeCooldown;
  final Future<void> Function(Duration) _delay;

  /// Whether this build is the kiosk at all. Injected rather than read inline
  /// so the retry policy is testable — the flavor gate is not what needs
  /// covering, the pass-until-durable loop is.
  final bool _enabled;

  StbKioskStatus _status = const StbKioskStatus.unsupported();

  /// Outcome of the most recent pass. Worth reporting at check-in: `ready ==
  /// false` is a box that will show the HOME chooser, and `durable == false` is
  /// one that will start doing so again after some future reboot.
  StbKioskStatus get status => _status;

  /// Passes run so far, across boot and resumes.
  int get passes => _passes;
  int _passes = 0;

  bool _running = false;
  bool _disposed = false;
  Timer? _cooldown;

  /// Runs the boot sequence and starts watching for resumes. Safe to call more
  /// than once; the second call is a no-op while the first is still running.
  Future<void> start() async {
    if (!_enabled || _disposed) return;
    WidgetsBinding.instance.addObserver(this);
    await _runSchedule();
  }

  Future<void> _runSchedule() async {
    if (_running || _disposed) return;
    _running = true;
    try {
      for (final gap in _schedule) {
        if (_disposed) return;
        if (gap > Duration.zero) await _delay(gap);
        if (_disposed) return;
        final status = await _pass();
        // Stop only when the box holds HOME *and* nothing can take it back.
        // `ready` alone is the state that silently reverts later, so keep
        // trying — a later pass may be the one that finally gets root.
        if (status.ready && status.durable) return;

        // No root AND no device owner means there is no privileged route on
        // this box at all, and four more identical failures will not create
        // one. Ask for the role NOW rather than at the end of the schedule —
        // otherwise the dialog lands ~45s after launch, by which time someone
        // is watching a channel, or the session has ended and it never shows.
        // The remaining passes still run: a late `su` grant is unlikely but
        // costs nothing to keep checking for.
        if (!status.ready && !status.root && !status.deviceOwner) {
          await _maybeRequestHomeRole();
        }
      }
      _reportUnresolved();
      // Belt and braces for the box that had a privileged route, tried it, and
      // still did not end up holding HOME.
      await _maybeRequestHomeRole();
    } finally {
      _running = false;
      _startCooldown();
    }
  }

  Future<void> _singlePass() async {
    if (_running || _disposed) return;
    _running = true;
    try {
      await _pass();
    } finally {
      _running = false;
      _startCooldown();
    }
  }

  Future<StbKioskStatus> _pass() async {
    _passes++;
    _status = await _system.runStartupMaintenance();
    logger.i('[STB] kiosk pass $_passes -> $_status');
    return _status;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_disposed || _running || _inCooldown) return;
    // Already settled — nothing to re-assert.
    if (_status.ready && _status.durable) return;
    // Coming back into FNDTV is usually someone having just picked us out of
    // the HOME chooser. The preference is settable right now, and if we do not
    // take it the same chooser returns on the next boot.
    unawaited(_singlePass());
  }

  /// Asks the system for the HOME role once per launch, when nothing else got
  /// us there.
  ///
  /// Fired automatically rather than hidden behind a button: on a box with no
  /// root and no device owner this is the ONLY way FNDTV can become the
  /// launcher, and nobody is going to go looking for it in a menu. The system
  /// puts up its own dialog and the user confirms — that one tap is
  /// unavoidable, Android does not let an app claim HOME silently.
  ///
  /// Once per process. Repeating it after someone has declined would trap the
  /// box in a dialog it cannot get past.
  Future<void> _maybeRequestHomeRole() async {
    if (_requestedRole || _disposed) return;
    if (await StbHomeRole.isHomeApp()) return;
    if (!await StbHomeRole.canRequest()) {
      logger.w('[STB] HOME role cannot be requested on this box — no route '
          'left to become the launcher from inside the app.');
      return;
    }
    _requestedRole = true;
    final shown = await StbHomeRole.request();
    logger.i('[STB] HOME role dialog shown=$shown — the role survives app '
        'updates, unlike the chooser\'s preferred-activity record.');
  }

  bool _requestedRole = false;

  void _reportUnresolved() {
    final s = _status;
    if (s.ready && s.durable) return;
    if (!s.ready) {
      logger.e(
        '[STB] KIOSK NOT HELD after $_passes passes — HOME belongs to '
        '${s.launcher ?? 'an unknown package'}, not us. '
        'root=${s.root} deviceOwner=${s.deviceOwner}. '
        'This box will show the home chooser on every boot.',
      );
    } else {
      logger.w(
        '[STB] Kiosk held but NOT durable — these can still take HOME: '
        '${s.homeCandidates.join(', ')}. '
        'root=${s.root} deviceOwner=${s.deviceOwner}. '
        'Expect the chooser to come back after a future reboot.',
      );
    }
  }

  bool get _inCooldown => _cooldown?.isActive ?? false;

  void _startCooldown() {
    if (_resumeCooldown <= Duration.zero) return;
    _cooldown?.cancel();
    _cooldown = Timer(_resumeCooldown, () {});
  }

  void dispose() {
    _disposed = true;
    _cooldown?.cancel();
    _cooldown = null;
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// The HOME role — the only route to being the launcher that needs neither root
/// nor device owner.
///
/// Worth having even though the chooser reaches the same screen, because of what
/// each one WRITES. Picking FNDTV from the chooser sets a preferred activity,
/// and Android drops that record whenever the set of HOME candidates changes —
/// including when FNDTV itself is updated. A box logged exactly that, 12 ms
/// after our own APK finished installing:
///
///   PackageManager: Result set changed, dropping preferred activity for
///   Intent { act=MAIN cat=[HOME, DEFAULT] }
///
/// So every update puts the chooser back: "we choose Always and it returns".
/// The role is held by RoleManager and survives a package update.
class StbHomeRole {
  const StbHomeRole._();

  static const MethodChannel _channel =
      MethodChannel('com.fndtv.videoplayer/device');

  /// Whether FNDTV is currently the resolved home app.
  static Future<bool> isHomeApp() => _invoke('isHomeApp');

  /// Whether the system role dialog can be shown — API 29+, the role exists on
  /// this image, and we don't already hold it.
  static Future<bool> canRequest() => _invoke('canRequestHomeRole');

  /// Shows the system "make FNDTV your Home app" dialog. Returns whether it was
  /// launched; the outcome arrives later, so re-check [isHomeApp] on resume.
  static Future<bool> request() => _invoke('requestHomeRole');

  static Future<bool> _invoke(String method) async {
    if (!StbSystemService.isStb) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      logger.w('[STB] $method failed: $e');
      return false;
    }
  }
}
