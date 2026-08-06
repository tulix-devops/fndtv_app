import 'package:app_logger/app_logger.dart';
import 'package:flutter/services.dart';

/// Package names to uninstall on STB boot (bloatware/other launchers).
/// Ported from the native launcher's `res/xml/unwanted_apps.xml`.
/// Removal is irreversible (root `pm uninstall`).
const List<String> kStbUnwantedApps = <String>[
  'com.google.android.youtube.tv', // YouTube TV
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
  'com.google.android.tvlauncher', // Google TV Home (competing launcher)
  // GMS/GSF disable is PARKED (2026-07-28): shipped together with the zero-copy
  // video change and the box came up on a blank screen, so we couldn't tell
  // which caused it. Re-introduce ON ITS OWN once the video change is cleared.
  // 'com.google.android.gms',
  // 'com.google.android.gsf',
];

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

  /// Detects the timezone from public-IP geolocation and (if the box is rooted)
  /// applies it to the system. Returns the detected timezone id, or null.
  /// Fire-and-forget safe: never throws.
  Future<String?> syncTimezone() => _invokeString('syncTimezone');

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

  /// Boot-time kiosk maintenance: device-owner provisioning, default-launcher
  /// takeover, removal of [unwantedApps] (uninstall), and disabling of
  /// [disabledComponents] / [disabledPackages] (blocked but kept). Returns a
  /// summary map. No-op without root. Fire-and-forget safe.
  Future<Map<String, Object?>> runStartupMaintenance({
    List<String> unwantedApps = kStbUnwantedApps,
    List<String> disabledComponents = kStbDisabledComponents,
    List<String> disabledPackages = kStbDisabledPackages,
  }) async {
    if (!isStb) return const {};
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
      return summary;
    } catch (e) {
      logger.w('[STB] runStartupMaintenance failed: $e');
      return const {};
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
