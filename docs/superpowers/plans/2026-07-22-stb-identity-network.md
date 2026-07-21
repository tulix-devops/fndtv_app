# STB Identity Display + Network Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the stb flavor, show the box identity (MAC/serial/device-id) globally and give kiosk users an in-app network manager (connectivity observer, offline overlay, Wi-Fi scan/join, Wired ⇄ Wi-Fi switch).

**Architecture:** New StbBridge natives (device-owner WifiManager APIs primary, root shell fallback) surfaced through a Dart `StbNetworkService`; a `ConnectivityObserver` (connectivity_plus + reachability probe) feeds a `NetworkCubit`; badge + offline overlay mount once in the existing stb-gated `MaterialApp.builder`; a new `TvNetworkPage` hangs off nav-rail index 7. Spec: `docs/superpowers/specs/2026-07-22-stb-identity-network-design.md`.

**Tech Stack:** Flutter 3.x / flutter_bloc, connectivity_plus ^6.1.0, Kotlin (StbBridge, `com.fndtv.videoplayer/stb` channel), existing root/device-owner helpers.

**Build gotchas (memory-verified):** `flutter build apk` REQUIRES `--flavor stb`; gradlew needs `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`; `kotlin.incremental=false` already set. `flutter analyze` exits 1 from pre-existing lint debt — the gate is **zero diagnostics in files this plan touches** (filter with Select-String).

---

### Task 1: Dependency + localization keys (EN/ES/FR)

**Files:**
- Modify: `pubspec.yaml` (dependencies block, after `http: ^1.1.0`)
- Modify: `packages/app_localization/lib/l10n/app_en.arb`
- Modify: `packages/app_localization/lib/l10n/app_es.arb`
- Modify: `packages/app_localization/lib/l10n/app_fr.arb`

- [ ] **Step 1: Add connectivity_plus to pubspec.yaml**

```yaml
  http: ^1.1.0
  connectivity_plus: ^6.1.0
```

- [ ] **Step 2: Add EN keys** — append inside the JSON object of `app_en.arb` (after the `updates*` block):

```json
  "navNetwork": "Network",
  "networkTitle": "Network",
  "networkConnectionCard": "Connection",
  "networkModeWifi": "Wi-Fi",
  "networkModeWired": "Wired",
  "networkStatusLabel": "Status",
  "networkStatusConnected": "Connected",
  "networkStatusOffline": "Offline",
  "networkSsid": "Network",
  "networkIp": "IP address",
  "networkEthernetCard": "Ethernet",
  "networkEthernetLinked": "Cable connected",
  "networkEthernetNoCable": "No cable detected",
  "networkDeviceCard": "This device",
  "networkDeviceMac": "MAC address",
  "networkDeviceSerial": "Serial number",
  "networkDeviceId": "Device ID",
  "networkDeviceVersion": "App version",
  "networkAvailable": "Available networks",
  "networkScan": "Scan",
  "networkScanning": "Scanning…",
  "networkNoneFound": "No networks found",
  "networkPasswordTitle": "Enter Wi-Fi password",
  "networkPasswordHint": "Password",
  "networkConnect": "Connect",
  "networkConnecting": "Connecting…",
  "networkJoinFailed": "Couldn't connect — check the password",
  "networkRetry": "Try again",
  "networkWiredWarnTitle": "No cable detected",
  "networkWiredWarnBody": "Switching to wired now will take the box offline until a cable is plugged in. Continue?",
  "networkWiredWarnConfirm": "Switch anyway",
  "networkWiredWarnCancel": "Cancel",
  "offlineTitle": "No internet connection",
  "offlineCta": "Set up network"
```

- [ ] **Step 3: Add ES keys** — same keys in `app_es.arb`:

```json
  "navNetwork": "Red",
  "networkTitle": "Red",
  "networkConnectionCard": "Conexión",
  "networkModeWifi": "Wi-Fi",
  "networkModeWired": "Por cable",
  "networkStatusLabel": "Estado",
  "networkStatusConnected": "Conectado",
  "networkStatusOffline": "Sin conexión",
  "networkSsid": "Red",
  "networkIp": "Dirección IP",
  "networkEthernetCard": "Ethernet",
  "networkEthernetLinked": "Cable conectado",
  "networkEthernetNoCable": "No se detecta cable",
  "networkDeviceCard": "Este dispositivo",
  "networkDeviceMac": "Dirección MAC",
  "networkDeviceSerial": "Número de serie",
  "networkDeviceId": "ID del dispositivo",
  "networkDeviceVersion": "Versión de la app",
  "networkAvailable": "Redes disponibles",
  "networkScan": "Buscar",
  "networkScanning": "Buscando…",
  "networkNoneFound": "No se encontraron redes",
  "networkPasswordTitle": "Introduce la contraseña Wi-Fi",
  "networkPasswordHint": "Contraseña",
  "networkConnect": "Conectar",
  "networkConnecting": "Conectando…",
  "networkJoinFailed": "No se pudo conectar — comprueba la contraseña",
  "networkRetry": "Reintentar",
  "networkWiredWarnTitle": "No se detecta cable",
  "networkWiredWarnBody": "Cambiar a cable ahora dejará el dispositivo sin conexión hasta que se conecte un cable. ¿Continuar?",
  "networkWiredWarnConfirm": "Cambiar igualmente",
  "networkWiredWarnCancel": "Cancelar",
  "offlineTitle": "Sin conexión a Internet",
  "offlineCta": "Configurar red"
```

- [ ] **Step 4: Add FR keys** — same keys in `app_fr.arb`:

```json
  "navNetwork": "Réseau",
  "networkTitle": "Réseau",
  "networkConnectionCard": "Connexion",
  "networkModeWifi": "Wi-Fi",
  "networkModeWired": "Filaire",
  "networkStatusLabel": "État",
  "networkStatusConnected": "Connecté",
  "networkStatusOffline": "Hors ligne",
  "networkSsid": "Réseau",
  "networkIp": "Adresse IP",
  "networkEthernetCard": "Ethernet",
  "networkEthernetLinked": "Câble connecté",
  "networkEthernetNoCable": "Aucun câble détecté",
  "networkDeviceCard": "Cet appareil",
  "networkDeviceMac": "Adresse MAC",
  "networkDeviceSerial": "Numéro de série",
  "networkDeviceId": "ID de l'appareil",
  "networkDeviceVersion": "Version de l'app",
  "networkAvailable": "Réseaux disponibles",
  "networkScan": "Rechercher",
  "networkScanning": "Recherche…",
  "networkNoneFound": "Aucun réseau trouvé",
  "networkPasswordTitle": "Saisir le mot de passe Wi-Fi",
  "networkPasswordHint": "Mot de passe",
  "networkConnect": "Se connecter",
  "networkConnecting": "Connexion…",
  "networkJoinFailed": "Connexion impossible — vérifiez le mot de passe",
  "networkRetry": "Réessayer",
  "networkWiredWarnTitle": "Aucun câble détecté",
  "networkWiredWarnBody": "Passer en filaire maintenant mettra le boîtier hors ligne jusqu'au branchement d'un câble. Continuer ?",
  "networkWiredWarnConfirm": "Changer quand même",
  "networkWiredWarnCancel": "Annuler",
  "offlineTitle": "Pas de connexion Internet",
  "offlineCta": "Configurer le réseau"
```

- [ ] **Step 5: Fetch + regenerate + verify**

Run (from repo root, PowerShell):
```powershell
C:\Users\Nika\flutter\bin\flutter.bat pub get
Set-Location packages\app_localization; C:\Users\Nika\flutter\bin\flutter.bat gen-l10n; Set-Location ..\..
C:\Users\Nika\flutter\bin\flutter.bat analyze --no-pub 2>$null | Select-String "app_localization|pubspec"
```
Expected: gen-l10n exits 0 (that's the same flow as `regen.sh`), filter output empty.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock packages/app_localization
git commit -m "feat(stb): add connectivity_plus + network/offline/identity l10n keys (en/es/fr)"
```

---

### Task 2: Native — StbBridge Wi-Fi/Ethernet methods

**Files:**
- Modify: `android/app/src/stb/kotlin/com/fndtv/videoplayer/StbBridge.kt`
- Modify: `android/app/src/stb/AndroidManifest.xml` (create the merge-manifest if it does not exist)

- [ ] **Step 1: Manifest permissions** — in the stb flavor manifest, inside `<manifest>` (create the file with just this if missing):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
</manifest>
```
(If the file exists, merge only the missing `<uses-permission>` lines.)

- [ ] **Step 2: Add imports to StbBridge.kt**

```kotlin
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
```

- [ ] **Step 3: Register the four new channel methods** — in `handle()`'s `when`, after the `"isRootAvailable"` line:

```kotlin
                    // network manager
                    "wifiStatus" -> wifiStatus()
                    "ethernetStatus" -> ethernetStatus()
                    "scanWifi" -> scanWifi()
                    "connectWifi" -> connectWifi(
                        call.argument<String>("ssid") ?: "",
                        call.argument<String>("password")
                    )
                    "setWifiEnabled" -> setWifiEnabled(call.argument<Boolean>("enabled") ?: true)
```

- [ ] **Step 4: Implement the natives** — add a new section before `// ─── root helper`:

```kotlin
    // ─── network manager (device-owner APIs primary, root shell fallback) ────

    private val wifi: WifiManager?
        get() = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    /** {enabled, ssid, ip} — ssid null when disconnected/unknown. */
    private fun wifiStatus(): Map<String, Any?> {
        val w = wifi
        var ssid: String? = try {
            @Suppress("DEPRECATION")
            w?.connectionInfo?.ssid?.trim('"')?.takeIf { it.isNotBlank() && it != "<unknown ssid>" }
        } catch (_: Throwable) { null }
        if (ssid == null && isRootAvailable()) {
            // A11+: `cmd wifi status` prints: Wifi is connected to "MySsid"
            val out = runSuCapture("cmd wifi status").output
            ssid = Regex("connected to \"(.+?)\"").find(out)?.groupValues?.get(1)
        }
        return mapOf(
            "enabled" to (try { w?.isWifiEnabled == true } catch (_: Throwable) { false }),
            "ssid" to ssid,
            "ip" to ipFromInterface("wlan0")
        )
    }

    /** {linked, ip} — linked = carrier up on eth0. */
    private fun ethernetStatus(): Map<String, Any?> {
        val linked = try {
            File("/sys/class/net/eth0/carrier").readText().trim() == "1"
        } catch (_: Throwable) { false }
        return mapOf("linked" to linked, "ip" to ipFromInterface("eth0"))
    }

    private fun ipFromInterface(name: String): String? = try {
        NetworkInterface.getByName(name)?.inetAddresses?.toList()
            ?.filterIsInstance<Inet4Address>()
            ?.firstOrNull { !it.isLoopbackAddress }?.hostAddress
    } catch (_: Throwable) { null }

    /**
     * Scan for networks. Primary: WifiManager (works API 10–35 for us — location
     * self-granted via root). Fallback: `cmd wifi list-scan-results` (A11+).
     * Returns a list of {ssid, secured, rssi} deduped by ssid (strongest kept).
     */
    private fun scanWifi(): List<Map<String, Any?>> {
        if (isRootAvailable()) {
            runSu(
                "pm grant ${context.packageName} android.permission.ACCESS_FINE_LOCATION",
                "pm grant ${context.packageName} android.permission.NEARBY_WIFI_DEVICES"
            )
        }
        val results = mutableListOf<Triple<String, Boolean, Int>>() // ssid, secured, rssi
        try {
            val w = wifi
            @Suppress("DEPRECATION") w?.startScan()
            Thread.sleep(2500) // give the chip a beat; cached results are fine too
            @Suppress("DEPRECATION")
            w?.scanResults?.forEach { r ->
                val ssid = r.SSID?.takeIf { it.isNotBlank() } ?: return@forEach
                val secured = listOf("WEP", "PSK", "EAP", "SAE").any { r.capabilities.contains(it) }
                results.add(Triple(ssid, secured, r.level))
            }
        } catch (t: Throwable) {
            Log.w(tag, "WifiManager scan failed", t)
        }
        if (results.isEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && isRootAvailable()) {
            // Header: "BSSID  Frequency  RSSI  Age(sec)  SSID  Flags"
            val out = runSuCapture("cmd wifi start-scan", "sleep 3", "cmd wifi list-scan-results").output
            for (line in out.lines().drop(1)) {
                val m = Regex(
                    "^\\s*([0-9a-fA-F:]{17})\\s+\\S+\\s+(-?\\d+).*?\\s{2,}(\\S.*?)\\s{2,}(\\[.*)?$"
                ).find(line) ?: continue
                val rssi = m.groupValues[2].toIntOrNull() ?: continue
                val ssid = m.groupValues[3].trim()
                if (ssid.isBlank()) continue
                val secured = m.groupValues[4].let { it.contains("WPA") || it.contains("WEP") || it.contains("SAE") }
                results.add(Triple(ssid, secured, rssi))
            }
        }
        return results
            .groupBy { it.first }
            .map { (_, group) -> group.maxBy { it.third } }
            .sortedByDescending { it.third }
            .map { mapOf("ssid" to it.first, "secured" to it.second, "rssi" to it.third) }
    }

    /**
     * Join a network. Primary: legacy WifiConfiguration add/enable — still
     * honoured for device-owner apps on API 29+ (and the only path on the
     * Android 10 X88 Pro 10 fleet). Fallback: `cmd wifi connect-network` (A11+).
     * Returns true when the join was INITIATED; Dart polls wifiStatus for the
     * outcome (a wrong password only surfaces as a timeout).
     */
    private fun connectWifi(ssid: String, password: String?): Boolean {
        if (ssid.isBlank()) return false
        try {
            val w = wifi ?: throw IllegalStateException("no WifiManager")
            @Suppress("DEPRECATION")
            if (w.isWifiEnabled == false) w.isWifiEnabled = true
            @Suppress("DEPRECATION")
            val conf = WifiConfiguration().apply {
                SSID = "\"$ssid\""
                if (password.isNullOrEmpty()) {
                    allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
                } else {
                    preSharedKey = "\"$password\""
                }
            }
            @Suppress("DEPRECATION")
            val netId = w.addNetwork(conf)
            if (netId >= 0) {
                @Suppress("DEPRECATION") w.disconnect()
                @Suppress("DEPRECATION") w.enableNetwork(netId, true)
                @Suppress("DEPRECATION") w.reconnect()
                Log.i(tag, "connectWifi: legacy path initiated for $ssid (netId=$netId)")
                return true
            }
            Log.w(tag, "connectWifi: addNetwork returned $netId for $ssid")
        } catch (t: Throwable) {
            Log.w(tag, "connectWifi legacy path failed", t)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && isRootAvailable()) {
            val cmd = if (password.isNullOrEmpty())
                "cmd wifi connect-network '${ssid.replace("'", "'\\''")}' open"
            else
                "cmd wifi connect-network '${ssid.replace("'", "'\\''")}' wpa2 '${password.replace("'", "'\\''")}'"
            return runSu(cmd) == 0
        }
        return false
    }

    /** Toggle Wi-Fi. Primary: DO-exempt setWifiEnabled; fallback: `svc wifi`. */
    private fun setWifiEnabled(enabled: Boolean): Boolean {
        try {
            @Suppress("DEPRECATION")
            if (wifi?.setWifiEnabled(enabled) == true) return true
        } catch (t: Throwable) {
            Log.w(tag, "setWifiEnabled($enabled) API path failed", t)
        }
        return runSu("svc wifi ${if (enabled) "enable" else "disable"}") == 0
    }
```

- [ ] **Step 5: Verify the stb APK compiles**

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
C:\Users\Nika\flutter\bin\flutter.bat build apk --flavor stb --debug
```
Expected: `√ Built build\app\outputs\flutter-apk\app-stb-debug.apk`. (Kotlin cache corruption → kill java daemons, wipe `build`/`android/.gradle`/`android/.kotlin`, retry — known issue.)

- [ ] **Step 6: Commit**

```bash
git add android/app/src/stb
git commit -m "feat(stb): native Wi-Fi/Ethernet bridge methods (DO APIs + root fallback)"
```

---

### Task 3: Dart `StbNetworkService` + models (TDD)

**Files:**
- Create: `lib/src/core/services/stb_network_service.dart`
- Test: `test/core/services/stb_network_service_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';

void main() {
  group('WifiNetwork.fromMap', () {
    test('parses fields and buckets rssi into level 1-4', () {
      final n = WifiNetwork.fromMap({'ssid': 'Home', 'secured': true, 'rssi': -60});
      expect(n.ssid, 'Home');
      expect(n.secured, isTrue);
      expect(n.level, 4);
    });

    test('rssi buckets: -90→1, -80→2, -70→3, -55→4', () {
      int lvl(int rssi) => WifiNetwork.fromMap({'ssid': 's', 'secured': false, 'rssi': rssi}).level;
      expect(lvl(-90), 1);
      expect(lvl(-80), 2);
      expect(lvl(-70), 3);
      expect(lvl(-55), 4);
    });

    test('tolerates missing fields', () {
      final n = WifiNetwork.fromMap(const {});
      expect(n.ssid, '');
      expect(n.secured, isFalse);
      expect(n.level, 1);
    });
  });

  group('StbNetworkStatus.fromMaps', () {
    test('merges wifi + ethernet maps', () {
      final s = StbNetworkStatus.fromMaps(
        wifi: {'enabled': true, 'ssid': 'Home', 'ip': '192.168.1.34'},
        ethernet: {'linked': false, 'ip': null},
      );
      expect(s.wifiEnabled, isTrue);
      expect(s.ssid, 'Home');
      expect(s.wifiIp, '192.168.1.34');
      expect(s.ethernetLinked, isFalse);
      expect(s.ethernetIp, isNull);
    });

    test('null maps degrade to defaults', () {
      final s = StbNetworkStatus.fromMaps(wifi: null, ethernet: null);
      expect(s.wifiEnabled, isFalse);
      expect(s.ssid, isNull);
      expect(s.ethernetLinked, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `C:\Users\Nika\flutter\bin\flutter.bat test test/core/services/stb_network_service_test.dart`
Expected: FAIL — `stb_network_service.dart` does not exist.

- [ ] **Step 3: Implement the service**

```dart
import 'package:app_logger/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart' show StbSystemService;

/// A Wi-Fi network found by a scan. [level] is 1 (weak) – 4 (strong).
class WifiNetwork {
  final String ssid;
  final bool secured;
  final int level;

  const WifiNetwork({required this.ssid, required this.secured, required this.level});

  factory WifiNetwork.fromMap(Map<Object?, Object?> map) {
    final rssi = (map['rssi'] as int?) ?? -100;
    return WifiNetwork(
      ssid: (map['ssid'] as String?) ?? '',
      secured: (map['secured'] as bool?) ?? false,
      level: _bucket(rssi),
    );
  }

  static int _bucket(int rssi) {
    if (rssi >= -60) return 4;
    if (rssi >= -73) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }
}

/// Snapshot of the box's link state (both interfaces).
class StbNetworkStatus {
  final bool wifiEnabled;
  final String? ssid;
  final String? wifiIp;
  final bool ethernetLinked;
  final String? ethernetIp;

  const StbNetworkStatus({
    required this.wifiEnabled,
    required this.ssid,
    required this.wifiIp,
    required this.ethernetLinked,
    required this.ethernetIp,
  });

  factory StbNetworkStatus.fromMaps({
    Map<Object?, Object?>? wifi,
    Map<Object?, Object?>? ethernet,
  }) =>
      StbNetworkStatus(
        wifiEnabled: (wifi?['enabled'] as bool?) ?? false,
        ssid: wifi?['ssid'] as String?,
        wifiIp: wifi?['ip'] as String?,
        ethernetLinked: (ethernet?['linked'] as bool?) ?? false,
        ethernetIp: ethernet?['ip'] as String?,
      );
}

/// Dart face of the StbBridge network methods. Fail-soft like
/// [StbSystemService]: every call is stb-gated, logs failures, never throws.
/// Methods are non-final so tests can fake by overriding.
class StbNetworkService {
  static const MethodChannel _channel = MethodChannel('com.fndtv.videoplayer/stb');

  Future<StbNetworkStatus> status() async {
    if (!StbSystemService.isStb) return StbNetworkStatus.fromMaps();
    try {
      final wifi = await _channel.invokeMethod<Map<Object?, Object?>>('wifiStatus');
      final eth = await _channel.invokeMethod<Map<Object?, Object?>>('ethernetStatus');
      return StbNetworkStatus.fromMaps(wifi: wifi, ethernet: eth);
    } catch (e) {
      logger.w('[STB] network status failed: $e');
      return StbNetworkStatus.fromMaps();
    }
  }

  Future<List<WifiNetwork>> scan() async {
    if (!StbSystemService.isStb) return const [];
    try {
      final res = await _channel.invokeMethod<List<Object?>>('scanWifi');
      return res
              ?.whereType<Map<Object?, Object?>>()
              .map(WifiNetwork.fromMap)
              .where((n) => n.ssid.isNotEmpty)
              .toList() ??
          const [];
    } catch (e) {
      logger.w('[STB] scanWifi failed: $e');
      return const [];
    }
  }

  /// Initiates a join; the outcome is observed by polling [status].
  Future<bool> connect(String ssid, {String? password}) async {
    if (!StbSystemService.isStb) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'connectWifi',
            {'ssid': ssid, 'password': password},
          ) ??
          false;
    } catch (e) {
      logger.w('[STB] connectWifi failed: $e');
      return false;
    }
  }

  Future<bool> setWifiEnabled(bool enabled) async {
    if (!StbSystemService.isStb) return false;
    try {
      return await _channel.invokeMethod<bool>('setWifiEnabled', {'enabled': enabled}) ?? false;
    } catch (e) {
      logger.w('[STB] setWifiEnabled failed: $e');
      return false;
    }
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**, then commit

```bash
git add lib/src/core/services/stb_network_service.dart test/core/services/stb_network_service_test.dart
git commit -m "feat(stb): StbNetworkService + WifiNetwork/StbNetworkStatus models"
```

---

### Task 4: `ConnectivityObserver` (TDD)

**Files:**
- Create: `lib/src/core/services/connectivity_observer.dart`
- Test: `test/core/services/connectivity_observer_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/connectivity_observer.dart';

void main() {
  test('emits offline when interface says none (no probe needed)', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () async => fail('probe must not run with no interface'),
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events, [false]);
    expect(observer.isOnline, isFalse);
    await observer.dispose();
  });

  test('interface up + probe ok -> online; probe fail -> offline', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    var probeResult = true;
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () async => probeResult,
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events, [true]);

    probeResult = false;
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(events, [true, false]);
    await observer.dispose();
  });

  test('does not re-emit unchanged state', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final observer = ConnectivityObserver(
      changes: changes.stream,
      probe: () async => true,
    );
    final events = <bool>[];
    observer.onlineStream.listen(events.add);

    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events, [true]);
    await observer.dispose();
  });
}
```

- [ ] **Step 2: Run to verify failure** (file missing), then implement:

```dart
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
```

**Required companion change** — add the probe endpoint to
`packages/commons/lib/http/api_list.dart` (after `commandAck`):

```dart
  /// Cheap reachability probe target on the box host (`GET /api/health`).
  static String get boxHealth => '$_boxUrl/health';
```

- [ ] **Step 3: Run tests — expect PASS**, then commit

```bash
git add lib/src/core/services/connectivity_observer.dart test/core/services/connectivity_observer_test.dart packages/commons/lib/http/api_list.dart
git commit -m "feat(stb): ConnectivityObserver — interface changes + reachability probe"
```

---

### Task 5: `NetworkCubit` (TDD)

**Files:**
- Create: `lib/src/bloc/network_cubit/network_cubit.dart`
- Test: `test/bloc/network_cubit_test.dart`
- Modify: `lib/src/ui/widgets/app_provider.dart` (`AppBlocProvider.providers`)

- [ ] **Step 1: Write the failing tests** — fakes override the service/observer:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/core/services/connectivity_observer.dart';
import 'package:fndtv/src/core/services/stb_network_service.dart';

class FakeNetworkService extends StbNetworkService {
  StbNetworkStatus next = StbNetworkStatus.fromMaps();
  List<WifiNetwork> scanResult = const [];
  bool connectResult = true;
  final connectCalls = <(String, String?)>[];

  @override
  Future<StbNetworkStatus> status() async => next;
  @override
  Future<List<WifiNetwork>> scan() async => scanResult;
  @override
  Future<bool> connect(String ssid, {String? password}) async {
    connectCalls.add((ssid, password));
    return connectResult;
  }

  @override
  Future<bool> setWifiEnabled(bool enabled) async => true;
}

void main() {
  NetworkCubit make(FakeNetworkService svc) => NetworkCubit(
        service: svc,
        observer: ConnectivityObserver(changes: const Stream.empty(), probe: () async => true),
        joinPollInterval: const Duration(milliseconds: 10),
        joinTimeout: const Duration(milliseconds: 50),
      );

  test('refreshStatus copies service snapshot into state', () async {
    final svc = FakeNetworkService()
      ..next = StbNetworkStatus.fromMaps(
        wifi: {'enabled': true, 'ssid': 'Home', 'ip': '10.0.0.2'},
        ethernet: {'linked': true, 'ip': '10.0.0.3'},
      );
    final cubit = make(svc);
    await cubit.refreshStatus();
    expect(cubit.state.ssid, 'Home');
    expect(cubit.state.ethernetLinked, isTrue);
    await cubit.close();
  });

  test('scan sets scanning then results', () async {
    final svc = FakeNetworkService()
      ..scanResult = const [WifiNetwork(ssid: 'A', secured: true, level: 3)];
    final cubit = make(svc);
    await cubit.scan();
    expect(cubit.state.scanning, isFalse);
    expect(cubit.state.networks.single.ssid, 'A');
    await cubit.close();
  });

  test('join success when polled status reaches target ssid', () async {
    final svc = FakeNetworkService();
    final cubit = make(svc);
    svc.next = StbNetworkStatus.fromMaps(wifi: {'enabled': true, 'ssid': 'A', 'ip': '1.2.3.4'});
    await cubit.join('A', password: 'pw');
    expect(svc.connectCalls, [('A', 'pw')]);
    expect(cubit.state.joinPhase, NetworkJoinPhase.idle);
    expect(cubit.state.ssid, 'A');
    await cubit.close();
  });

  test('join times out -> failed phase', () async {
    final svc = FakeNetworkService(); // status never reports ssid B
    final cubit = make(svc);
    await cubit.join('B', password: 'bad');
    expect(cubit.state.joinPhase, NetworkJoinPhase.failed);
    await cubit.close();
  });

  test('overlay suppression flag toggles', () async {
    final cubit = make(FakeNetworkService());
    cubit.suppressOverlay(true);
    expect(cubit.state.overlaySuppressed, isTrue);
    cubit.suppressOverlay(false);
    expect(cubit.state.overlaySuppressed, isFalse);
    await cubit.close();
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement the cubit:

```dart
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
```

- [ ] **Step 3: Run tests — expect PASS.**

- [ ] **Step 4: Provide the cubit** — in `AppBlocProvider` (`app_provider.dart`), add to `MultiBlocProvider.providers` (with imports for `NetworkCubit`, `ConnectivityObserver`, `StbNetworkService`, `StbSystemService`):

```dart
        // STB network manager — observer + status live for the whole app run.
        BlocProvider<NetworkCubit>(
          lazy: false,
          create: (ctx) {
            final stb = StbSystemService();
            final cubit = NetworkCubit(
              service: StbNetworkService(),
              observer: ConnectivityObserver(),
              // Degrade to status-only when the box has neither device-owner
              // nor root (spec: error handling).
              checkManageable: () async =>
                  await stb.isDeviceOwner() || await stb.isRootAvailable(),
            );
            if (StbSystemService.isStb) cubit.refreshStatus();
            return cubit;
          },
        ),
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/bloc/network_cubit lib/src/ui/widgets/app_provider.dart test/bloc/network_cubit_test.dart
git commit -m "feat(stb): NetworkCubit — status/scan/join/wired-toggle + offline state"
```

---

### Task 6: `DeviceIdentityCubit` (TDD)

**Files:**
- Create: `lib/src/bloc/device_identity_cubit/device_identity_cubit.dart`
- Test: `test/bloc/device_identity_cubit_test.dart`
- Modify: `lib/src/ui/widgets/app_provider.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';

void main() {
  test('load() fills identity from injected readers', () async {
    final cubit = DeviceIdentityCubit(
      readMac: () async => 'A4:3E:31:7B:22:10',
      readSerial: () async => 'X88P14-004512',
      readDeviceId: () async => 'd41f-9c2a',
      readVersion: () async => '1.3.2',
    );
    await cubit.load();
    expect(cubit.state.mac, 'A4:3E:31:7B:22:10');
    expect(cubit.state.serial, 'X88P14-004512');
    expect(cubit.state.deviceId, 'd41f-9c2a');
    expect(cubit.state.version, '1.3.2');
    expect(cubit.state.loaded, isTrue);
    await cubit.close();
  });

  test('reader errors leave empty values, still marks loaded', () async {
    final cubit = DeviceIdentityCubit(
      readMac: () async => throw Exception('boom'),
      readSerial: () async => '',
      readDeviceId: () async => null,
      readVersion: () async => '',
    );
    await cubit.load();
    expect(cubit.state.mac, '');
    expect(cubit.state.deviceId, isNull);
    expect(cubit.state.loaded, isTrue);
    await cubit.close();
  });
}
```

- [ ] **Step 2: Run to verify failure**, then implement:

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceIdentityState extends Equatable {
  final String mac;
  final String serial;
  final String? deviceId;
  final String version;
  final bool loaded;

  const DeviceIdentityState({
    this.mac = '',
    this.serial = '',
    this.deviceId,
    this.version = '',
    this.loaded = false,
  });

  @override
  List<Object?> get props => [mac, serial, deviceId, version, loaded];
}

/// Loads the box identity once for the badge / Network page / offline overlay.
/// Reader functions are injected so the cubit is trivially testable; production
/// wiring lives in AppBlocProvider.
class DeviceIdentityCubit extends Cubit<DeviceIdentityState> {
  DeviceIdentityCubit({
    required Future<String> Function() readMac,
    required Future<String> Function() readSerial,
    required Future<String?> Function() readDeviceId,
    required Future<String> Function() readVersion,
  })  : _readMac = readMac,
        _readSerial = readSerial,
        _readDeviceId = readDeviceId,
        _readVersion = readVersion,
        super(const DeviceIdentityState());

  final Future<String> Function() _readMac;
  final Future<String> Function() _readSerial;
  final Future<String?> Function() _readDeviceId;
  final Future<String> Function() _readVersion;

  Future<void> load() async {
    Future<T> safe<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (_) {
        return fallback;
      }
    }

    emit(DeviceIdentityState(
      mac: await safe(_readMac, ''),
      serial: await safe(_readSerial, ''),
      deviceId: await safe(_readDeviceId, null),
      version: await safe(_readVersion, ''),
      loaded: true,
    ));
  }
}
```

- [ ] **Step 3: Run tests — expect PASS.**

- [ ] **Step 4: Provide it** — in `AppBlocProvider`, after the `NetworkCubit` provider (imports: `DeviceIdentityService`, `kStbDeviceIdKey`, `LocalStorage`, `PackageInfo` from `package_info_plus`):

```dart
        BlocProvider<DeviceIdentityCubit>(
          lazy: false,
          create: (ctx) {
            final identity = DeviceIdentityService();
            final storage = ctx.read<LocalStorage>();
            return DeviceIdentityCubit(
              readMac: identity.getWifiMac,
              readSerial: identity.getSerialNumber,
              readDeviceId: () => storage.get<String>(kStbDeviceIdKey),
              readVersion: () async => (await PackageInfo.fromPlatform()).version,
            )..load();
          },
        ),
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/bloc/device_identity_cubit lib/src/ui/widgets/app_provider.dart test/bloc/device_identity_cubit_test.dart
git commit -m "feat(stb): DeviceIdentityCubit — mac/serial/deviceId/version snapshot"
```

---

### Task 7: Global identity badge + offline overlay (MaterialApp.builder)

**Files:**
- Create: `lib/src/ui/widgets/stb/tv_identity_badge.dart`
- Create: `lib/src/ui/widgets/stb/tv_offline_overlay.dart`
- Create: `lib/src/core/services/app_route_tracker.dart`
- Modify: `lib/src/ui/app.dart`

- [ ] **Step 1: Route tracker** (`app_route_tracker.dart`) — lets the badge hide during fullscreen playback:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Navigator observer exposing the current route name — used by the identity
/// badge to hide itself over fullscreen video. Unnamed pushed routes (e.g.
/// TvUpdatesPage) report null, which counts as "show the badge".
class AppRouteTracker extends NavigatorObserver {
  static final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      currentRoute.value = route.settings.name;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      currentRoute.value = previousRoute?.settings.name;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      currentRoute.value = newRoute?.settings.name;
}
```

- [ ] **Step 2: Identity badge** (`tv_identity_badge.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';
import 'package:fndtv/src/core/services/app_route_tracker.dart';
import 'package:fndtv/src/index.dart' show VideoPlayerPage;
import 'package:google_fonts/google_fonts.dart';

/// One dim line under the TV clock, on every screen: `MAC … · SN …`.
/// Support asks the customer to read the top-right corner — that's this.
class TvIdentityBadge extends StatelessWidget {
  const TvIdentityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppRouteTracker.currentRoute,
      builder: (context, route, _) {
        if (route == VideoPlayerPage.path) return const SizedBox.shrink();
        return BlocBuilder<DeviceIdentityCubit, DeviceIdentityState>(
          builder: (context, id) {
            if (!id.loaded || (id.mac.isEmpty && id.serial.isEmpty)) {
              return const SizedBox.shrink();
            }
            final parts = <String>[
              if (id.mac.isNotEmpty) 'MAC ${id.mac}',
              if (id.serial.isNotEmpty) 'SN ${id.serial}',
            ];
            return Positioned(
              top: 48,
              right: 24,
              child: IgnorePointer(
                child: Text(
                  parts.join(' · '),
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 3: Offline overlay** (`tv_offline_overlay.dart`):

```dart
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
```

- [ ] **Step 4: Mount globally in `app.dart`** — add a navigator key at top level (below imports):

```dart
/// Global navigator — lets the offline overlay (which lives OUTSIDE the
/// Navigator, in MaterialApp.builder) push the Network page.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
```

Then change the `MaterialApp` (imports: `TvIdentityBadge`, `TvOfflineOverlay`, `AppRouteTracker`):

```dart
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: appNavigatorKey,
                navigatorObservers: [AppRouteTracker()],
                // STB: power guard + global identity badge + offline overlay,
                // stacked over every route.
                builder: StbSystemService.isStb
                    ? (context, child) => StbPowerGuard(
                          child: Stack(
                            children: [
                              child ?? const SizedBox.shrink(),
                              const TvIdentityBadge(),
                              const TvOfflineOverlay(),
                            ],
                          ),
                        )
                    : null,
```

- [ ] **Step 5: Verify** — `flutter analyze` filtered to the new/modified files shows zero diagnostics:

```powershell
C:\Users\Nika\flutter\bin\flutter.bat analyze --no-pub 2>$null | Select-String "tv_identity_badge|tv_offline_overlay|app_route_tracker|app\.dart"
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/ui/widgets/stb lib/src/core/services/app_route_tracker.dart lib/src/ui/app.dart
git commit -m "feat(stb): global identity badge + offline overlay via MaterialApp.builder"
```

---

### Task 8: `TvNetworkPage` + nav-rail wiring

**Files:**
- Create: `lib/src/ui/pages/network/tv_network_page.dart`
- Modify: `lib/src/ui/pages/main/main_container_page.dart`

- [ ] **Step 1: Page** — follows `TvUpdatesPage` patterns (kTvBg scaffold, focusable red-outline buttons). Full file:

```dart
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
```

- [ ] **Step 2: Nav-rail wiring** — in `main_container_page.dart`:

Add import:
```dart
import 'package:fndtv/src/ui/pages/network/tv_network_page.dart';
```

After `_kUpdatesNavIndex` (line ~127), add:
```dart
  /// STB only — the in-app network manager (kiosk boxes can't reach Android
  /// Settings). Sits last, so its absence on other flavors shifts nothing.
  static const int _kNetworkNavIndex = 7;
```

In `_onNavSelected`, before the `_onTabTapped(index)` fallthrough:
```dart
    if (index == _kNetworkNavIndex) {
      _openNetworkPage();
      return;
    }
```

Next to `_openUpdatesPage`:
```dart
  Future<void> _openNetworkPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TvNetworkPage()),
    );
    if (mounted) _scaffoldKey.currentState?.requestNavFocus();
  }
```

In `navigationItems`, after the Updates entry (import `StbSystemService` if not already imported here):
```dart
                  // STB: in-app network manager — opens a full-screen page.
                  if (StbSystemService.isStb)
                    (label: context.l.navNetwork, icon: Icons.wifi_rounded),
```

- [ ] **Step 3: Verify**

```powershell
C:\Users\Nika\flutter\bin\flutter.bat analyze --no-pub 2>$null | Select-String "tv_network_page|main_container_page"
C:\Users\Nika\flutter\bin\flutter.bat test
```
Expected: empty filter output; all tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/ui/pages/network lib/src/ui/pages/main/main_container_page.dart
git commit -m "feat(stb): TvNetworkPage — scan/join, wired toggle, identity card + nav item"
```

---

### Task 9: Full verification

- [ ] **Step 1: Static + unit gate**

```powershell
C:\Users\Nika\flutter\bin\flutter.bat analyze --no-pub 2>$null | Select-String "network|identity|connectivity|stb_bridge|app\.dart|main_container"
C:\Users\Nika\flutter\bin\flutter.bat test
```
Expected: no diagnostics in touched files; every test passes.

- [ ] **Step 2: Build the stb APK**

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
C:\Users\Nika\flutter\bin\flutter.bat build apk --flavor stb --debug
```

- [ ] **Step 3: Emulator smoke** (`Television_4K_2` AVD — x86_64 google-tv; emulator/adb in `C:\Users\Nika\AppData\Local\Android\Sdk\{emulator,platform-tools}`; NOT `Television_4K`, which is 32-bit):
  1. Install `build/app/outputs/flutter-apk/app-stb-debug.apk`, launch.
  2. Badge: MAC/SN line appears top-right under the clock on Home.
  3. Nav rail: Network item present at the bottom; opens the page; D-pad reaches every control; Back returns focus to the rail.
  4. Scan lists the emulator's `AndroidWifi` AP. Joining may legitimately fail
     on the emulator (the app is neither device-owner nor rooted there — the
     degrade path may hide join controls entirely, which is correct behavior);
     the join happy-path is a REAL-BOX check, not an emulator gate.
  5. Toggle airplane mode via `adb shell cmd connectivity airplane-mode enable` → offline overlay appears with identity line + CTA; `…disable` → overlay auto-dismisses.
  6. Network page open while offline → no overlay on top of it.
- [ ] **Step 4: Real-box checklist (X88, deferred until a box is on the bench — record results in the dev report):** DO/root scan+join on a real AP, wrong-password → failure message, Wired ⇄ Wi-Fi both directions with/without cable, badge/overlay over real content, FR/ES strings spot-check.

- [ ] **Step 5: Final commit if anything shifted during verification**

```bash
git add -A
git commit -m "chore(stb): verification fixes for identity + network manager"
```
