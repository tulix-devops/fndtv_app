import 'package:app_logger/app_logger.dart';
import 'package:flutter/services.dart';

/// Preinstalled apps the box should not offer, removed on STB boot.
///
/// This list is for **bloat only**. Competing launchers no longer belong here:
/// the native side now discovers every package that answers the HOME intent and
/// neutralises all of them, because the launcher that steals the box is by
/// definition the one nobody thought to add to a static list. `com.smartbox.
/// launcher` stays purely so it is also removed as an app, not just as a HOME
/// candidate.
///
/// Removal is `pm uninstall --user 0` (the APK survives on /system, so a factory
/// reset restores it), falling back to `pm disable-user` for packages the
/// firmware refuses to uninstall.
const List<String> kStbUnwantedApps = <String>[
  // YouTube ships under different ids depending on the firmware image: the
  // leanback build on the Android TV boxes, the phone build on the AOSP-tablet
  // ones. Boxes in the field have had both, so both are listed — an id that
  // isn't present costs one `pm list` and no writes.
  'com.google.android.youtube.tv', // YouTube (Android TV)
  'com.google.android.youtube', // YouTube (phone/tablet build)
  'com.google.android.apps.youtube.music', // YouTube Music
  'com.google.android.videos', // Google TV / Play Movies
  'com.netflix.mediaclient', // Netflix
  'com.amazon.amazonvideo.livingroom', // Prime Video
  'com.smartbox.launcher', // Smartbox Launcher
  'com.android.vending', // Google Play Store
  'com.google.android.katniss', // Google Assistant
];

/// Component targets (`pkg/.Activity`) to DISABLE (not uninstall) on STB boot —
/// things that can't be removed but should be blocked. Ported from the native
/// `res/xml/disabled_apps.xml`. Disabling the TV Settings activity stops the
/// remote from opening system settings.
const List<String> kStbDisabledComponents = <String>[
  'com.android.tv.settings/.MainSettings', // TV Settings Main
];

/// Package targets to DISABLE (not uninstall) on STB boot.
///
/// Google Play Services is disabled for **performance**, not tidiness: a box
/// logcat (X88 Pro 14, 2026-07-28) caught `ANR in com.google.android.gms.unstable
/// — failed to complete startup`, with GMS stuck in a restart loop burning ~39%
/// CPU (`gms` 30% + `gms.persistent` 8.7%) on a box already pegged at 99% total.
/// That starvation — not the video player — was what made playback stutter.
/// The kiosk needs nothing from GMS: MDM runs on check-in polling (not FCM) and
/// the Play Store is already uninstalled.
///
/// Reversible if ever needed (e.g. Widevine DRM or a future FCM push channel):
/// remove the entry, or on the box `pm enable com.google.android.gms`.
const List<String> kStbDisabledPackages = <String>[
  'com.rockchips.mediacenter', // Rockchip Media Center
  // Google TV Home is now also caught by HOME-candidate discovery, which runs
  // first and disables it; this entry is a harmless belt-and-braces for boxes
  // where the query comes back empty.
  'com.google.android.tvlauncher', // Google TV Home (competing launcher)
  // GMS/GSF disable is PARKED (2026-07-28): shipped together with the zero-copy
  // video change and the box came up on a blank screen, so we couldn't tell
  // which caused it. Re-introduce ON ITS OWN once the video change is cleared.
  // 'com.google.android.gms',
  // 'com.google.android.gsf',
];

/// A timezone resolved from public-IP geolocation.
class StbTimezone {
  const StbTimezone({
    required this.id,
    required this.offsetSeconds,
    required this.applied,
  });

  /// IANA id, e.g. `Europe/Paris`.
  final String id;

  /// Current offset from UTC in seconds, DST included.
  final int offsetSeconds;

  /// Whether it was also written to the SYSTEM zone. False without root — the
  /// box keeps reporting the wrong zone and only the app renders correctly.
  final bool applied;

  @override
  String toString() =>
      'StbTimezone($id, ${offsetSeconds}s, applied: $applied)';
}

/// Verified outcome of one kiosk-maintenance pass.
///
/// Two separate questions, and the difference is what the field has been
/// living with:
///  - [ready] — is FNDTV the HOME app *right now*?
///  - [durable] — will it still be after the next reboot? False means the pin
///    rests on a preferred-activity record with other launchers still installed,
///    which Android drops as soon as the candidate set moves. A box can be
///    perfectly fine today and back on the chooser tomorrow.
class StbKioskStatus {
  const StbKioskStatus({
    required this.ready,
    required this.durable,
    required this.root,
    required this.deviceOwner,
    required this.launcher,
    required this.homeCandidates,
    required this.summary,
  });

  /// Off-flavor, or the channel call failed — nothing is known, nothing to do.
  const StbKioskStatus.unsupported()
      : ready = false,
        durable = false,
        root = false,
        deviceOwner = false,
        launcher = null,
        homeCandidates = const [],
        summary = const {};

  factory StbKioskStatus.fromSummary(Map<String, Object?> summary) {
    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];
    return StbKioskStatus(
      ready: summary['kioskReady'] == true,
      durable: summary['kioskDurable'] == true,
      root: summary['root'] == true,
      deviceOwner: summary['deviceOwner'] == true,
      launcher: summary['launcherAfter'] as String?,
      homeCandidates: strings(summary['homeCandidatesAfter']),
      summary: summary,
    );
  }

  /// FNDTV is the default HOME app.
  final bool ready;

  /// [ready], and nothing left that can take HOME back.
  final bool durable;

  final bool root;
  final bool deviceOwner;

  /// Package holding HOME after the pass.
  final String? launcher;

  /// Other packages that can still answer HOME.
  final List<String> homeCandidates;

  /// The raw native summary, for logs and check-in reporting.
  final Map<String, Object?> summary;

  @override
  String toString() => 'StbKioskStatus(ready: $ready, durable: $durable, '
      'root: $root, deviceOwner: $deviceOwner, launcher: $launcher, '
      'homeCandidates: $homeCandidates)';
}

/// Dart side of the STB-only native bridge (`com.fndtv.videoplayer/stb`).
///
/// Only meaningful on the `stb` flavor — [isStb] gates every call, and on any
/// other build the methods short-circuit to safe defaults (the native channel
/// isn't registered there). Backed by `StbBridge.kt`.
///
/// Foundation surface — §8 device/network info + §7 timezone sync. §6 power and
/// §1 kiosk methods will be added here as they land.
class StbSystemService {
  StbSystemService();

  static const MethodChannel _channel =
      MethodChannel('com.fndtv.videoplayer/stb');

  /// True when running the set-top-box build (`--flavor stb`).
  static bool get isStb => appFlavor == 'stb';

  Future<String?> ipAddress() => _invokeString('ipAddress');

  Future<String?> macAddress() => _invokeString('macAddress');

  Future<String?> cpuSerial() => _invokeString('cpuSerial');

  /// "Wi-Fi" | "Ethernet" | "Cellular" | "Other" | "Disconnected".
  Future<String?> connectionType() => _invokeString('connectionType');

  Future<bool> isRootAvailable() async {
    if (!isStb) return false;
    try {
      return await _channel.invokeMethod<bool>('isRootAvailable') ?? false;
    } catch (e) {
      logger.w('[STB] isRootAvailable failed: $e');
      return false;
    }
  }

  /// Detects the box's timezone from public-IP geolocation and, when root
  /// allows, applies it to the system. Null when nothing resolved (offline).
  ///
  /// The offset matters more than the id: applying the zone needs root, so on a
  /// box where `su` is refused the system zone stays wrong and `toLocal()` is
  /// permanently out. [StbClock] renders through the offset instead.
  Future<StbTimezone?> syncTimezone() async {
    if (!isStb) return null;
    try {
      final res =
          await _channel.invokeMethod<Map<Object?, Object?>>('syncTimezone');
      if (res == null) return null;
      final id = res['id'] as String?;
      final offset = res['offsetSeconds'] as int?;
      if (id == null || offset == null) return null;
      return StbTimezone(
        id: id,
        offsetSeconds: offset,
        applied: res['applied'] == true,
      );
    } catch (e) {
      logger.w('[STB] syncTimezone failed: $e');
      return null;
    }
  }

  /// Logs the box's device/network info once (field diagnostics + a smoke test
  /// that the native bridge is wired). No-op off the stb flavor.
  Future<void> logDiagnostics() async {
    if (!isStb) return;
    final results = await Future.wait([
      ipAddress(),
      macAddress(),
      cpuSerial(),
      connectionType(),
      isRootAvailable(),
    ]);
    logger.i(
      '[STB] diagnostics — ip=${results[0]}, mac=${results[1]}, '
      'serial=${results[2]}, net=${results[3]}, root=${results[4]}',
    );
  }

  // ─── §6 power ───────────────────────────────────────────────────────────────

  /// Puts the box into standby (root KEYCODE_SLEEP). Returns success.
  Future<bool> sleep() => _invokeBool('sleep');

  /// Reboots the box (DevicePolicyManager if device-owner, else root).
  Future<bool> reboot() => _invokeBool('reboot');

  // ─── §1 kiosk ─────────────────────────────────────────────────────────────

  Future<bool> isDeviceOwner() => _invokeBool('isDeviceOwner');

  /// Package name of the current default HOME launcher.
  Future<String?> defaultLauncher() => _invokeString('defaultLauncher');

  /// Every OTHER package that can currently answer the HOME intent — i.e. that
  /// can appear in the "Use ___ as Home" chooser. Empty means nothing can take
  /// the box from us.
  Future<List<String>> homeCandidates() async {
    if (!isStb) return const [];
    try {
      final res = await _channel.invokeMethod<List<Object?>>('homeCandidates');
      return res?.whereType<String>().toList() ?? const [];
    } catch (e) {
      logger.w('[STB] homeCandidates failed: $e');
      return const [];
    }
  }

  /// Read-only snapshot of everything the kiosk takeover depends on, for
  /// display on the box itself.
  ///
  /// Exists because a box in a customer's home is not on adb: "it did the same
  /// thing" is not a diagnosis, and a photo of this screen is. Keys mirror
  /// `StbBridge.kioskDiagnostics`. Empty off-flavor or on channel failure.
  Future<Map<String, Object?>> kioskDiagnostics() async {
    if (!isStb) return const {};
    try {
      final res =
          await _channel.invokeMethod<Map<Object?, Object?>>('kioskDiagnostics');
      return res?.map((k, v) => MapEntry(k.toString(), v)) ?? const {};
    } catch (e) {
      logger.w('[STB] kioskDiagnostics failed: $e');
      return const {};
    }
  }

  Future<bool> setDefaultLauncher() => _invokeBool('setDefaultLauncher');

  Future<bool> setupDeviceOwner() => _invokeBool('setupDeviceOwner');

  /// Uninstalls each package (root). Returns those actually removed.
  Future<List<String>> uninstallPackages(List<String> packages) async {
    if (!isStb || packages.isEmpty) return const [];
    try {
      final res = await _channel.invokeMethod<List<Object?>>(
        'uninstallPackages',
        {'packages': packages},
      );
      return res?.whereType<String>().toList() ?? const [];
    } catch (e) {
      logger.w('[STB] uninstallPackages failed: $e');
      return const [];
    }
  }

  /// Disables (does not uninstall) a component target `pkg/.Activity` via root —
  /// e.g. `com.android.tv.settings/.MainSettings` to block system settings.
  Future<bool> disableComponent(String component) async {
    if (!isStb || component.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'disableComponent',
            {'component': component},
          ) ??
          false;
    } catch (e) {
      logger.w('[STB] disableComponent failed: $e');
      return false;
    }
  }

  /// Disables (does not uninstall) a package via root.
  Future<bool> disablePackage(String package) async {
    if (!isStb || package.isEmpty) return false;
    try {
      return await _channel
              .invokeMethod<bool>('disablePackage', {'package': package}) ??
          false;
    } catch (e) {
      logger.w('[STB] disablePackage failed: $e');
      return false;
    }
  }

  /// Enables ADB-over-TCP only for privileged roles ("admin"/"developer");
  /// disables for anyone else.
  Future<bool> configureAdbTcp(String? user) async {
    if (!isStb) return false;
    try {
      return await _channel
              .invokeMethod<bool>('configureAdbTcp', {'user': user}) ??
          false;
    } catch (e) {
      logger.w('[STB] configureAdbTcp failed: $e');
      return false;
    }
  }

  /// Boot-time kiosk maintenance: competing-launcher removal, unwanted-app
  /// removal, then the HOME takeover — in that order, because pinning HOME
  /// before the candidate set is final makes Android drop the preference again.
  ///
  /// Returns the verified outcome, not a record of what was attempted. Callers
  /// should retry while [StbKioskStatus.ready] is false — see `StbKioskGuard`.
  /// No-op off the stb flavor. Never throws.
  Future<StbKioskStatus> runStartupMaintenance({
    List<String> unwantedApps = kStbUnwantedApps,
    List<String> disabledComponents = kStbDisabledComponents,
    List<String> disabledPackages = kStbDisabledPackages,
  }) async {
    if (!isStb) return const StbKioskStatus.unsupported();
    try {
      final res = await _channel.invokeMethod<Map<Object?, Object?>>(
        'runStartupMaintenance',
        {
          'unwantedApps': unwantedApps,
          'disabledComponents': disabledComponents,
          'disabledPackages': disabledPackages,
        },
      );
      final summary = res?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
      logger.i('[STB] startup maintenance: $summary');
      return StbKioskStatus.fromSummary(summary);
    } catch (e) {
      logger.w('[STB] runStartupMaintenance failed: $e');
      return const StbKioskStatus.unsupported();
    }
  }

  Future<bool> _invokeBool(String method) async {
    if (!isStb) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (e) {
      logger.w('[STB] $method failed: $e');
      return false;
    }
  }

  Future<String?> _invokeString(String method) async {
    if (!isStb) return null;
    try {
      return await _channel.invokeMethod<String>(method);
    } catch (e) {
      logger.w('[STB] $method failed: $e');
      return null;
    }
  }
}
