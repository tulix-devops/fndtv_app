package com.fndtv.videoplayer

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.DataOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.Inet4Address
import java.net.NetworkInterface
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors

/**
 * STB-only native bridge (adopted from the reference native FNDTV launcher).
 *
 * Registered reflectively by [MainActivity] only when this class exists (i.e.
 * the `stb` flavor); the `normal` flavor never loads it. Backs the
 * `com.fndtv.videoplayer/stb` MethodChannel consumed by Dart's StbSystemService.
 *
 * Covers §8 device/network info, §7 timezone sync, §6 power (sleep/reboot),
 * §1 kiosk (device-owner, default-launcher, unwanted-app removal, ADB-TCP), and
 * a network-manager surface (Wi-Fi status/scan/join/toggle, Ethernet status)
 * built on device-owner WifiManager APIs with root-shell (`cmd wifi`/`svc wifi`)
 * fallback. The kiosk/power/timezone-apply features require **root +
 * device-owner** and only take effect on the real box, not the emulator.
 */
class StbBridge(private val context: Context) {

    private val tag = "StbBridge"
    private val channelName = "com.fndtv.videoplayer/stb"
    private val io = Executors.newSingleThreadExecutor()
    // Network calls (scanWifi's ~2.5-5s scan wait, connectWifi) block for long
    // stretches; a dedicated executor keeps them off `io` so they can't stall
    // reboot/sleep/kiosk calls or a concurrent wifiStatus poll queued behind them.
    private val netIo = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Methods dispatched to [netIo] instead of [io]; see its comment. */
    private val networkMethods = setOf(
        "wifiStatus", "ethernetStatus", "scanWifi", "connectWifi", "setWifiEnabled"
    )

    private val adbTcpAllowedUsers = setOf("admin", "developer")
    private val adbTcpPortProperties = listOf(
        "adb.tcp.port",
        "service.adb.tcp.port",
        "persist.adb.tcp.port",
        "persist.service.adb.tcp.port"
    )

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        // Everything here does blocking IO (sysfs, /proc, network, `su`), so run
        // off the platform thread and post the reply back. Network methods run
        // on their own executor (see `netIo`) so a scan/connect can't stall
        // reboot/sleep/kiosk calls, or a concurrent wifiStatus poll, queued
        // behind it on `io`.
        val executor = if (call.method in networkMethods) netIo else io
        executor.execute { dispatch(call, result) }
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        val reply: Any? = try {
            when (call.method) {
                // §8 device / network info
                "ipAddress" -> getIpAddress()
                "macAddress" -> getMacAddress()
                "cpuSerial" -> getCpuSerial()
                "connectionType" -> getConnectionType()
                "isRootAvailable" -> isRootAvailable()
                // network manager
                "wifiStatus" -> wifiStatus()
                "ethernetStatus" -> ethernetStatus()
                "scanWifi" -> scanWifi()
                "connectWifi" -> connectWifi(
                    call.argument<String>("ssid") ?: "",
                    call.argument<String>("password"),
                    call.argument<String>("security")
                )
                "setWifiEnabled" -> setWifiEnabled(call.argument<Boolean>("enabled") ?: true)
                // §7 timezone
                "syncTimezone" -> syncTimezone()
                // §6 power
                "sleep" -> sleep()
                "reboot" -> reboot()
                // §1 kiosk
                "isDeviceOwner" -> isDeviceOwner()
                "defaultLauncher" -> defaultLauncher()
                "setDefaultLauncher" -> setDefaultLauncher()
                "setupDeviceOwner" -> setupDeviceOwner()
                "uninstallPackages" ->
                    uninstallPackages(call.argument<List<String>>("packages") ?: emptyList())
                "disableComponent" ->
                    disableComponent(call.argument<String>("component") ?: "")
                "disablePackage" ->
                    disablePackage(call.argument<String>("package") ?: "")
                "configureAdbTcp" -> configureAdbTcp(call.argument<String>("user"))
                "runStartupMaintenance" ->
                    runStartupMaintenance(
                        call.argument<List<String>>("unwantedApps") ?: emptyList(),
                        call.argument<List<String>>("disabledComponents") ?: emptyList(),
                        call.argument<List<String>>("disabledPackages") ?: emptyList()
                    )
                else -> NOT_IMPLEMENTED
            }
        } catch (t: Throwable) {
            Log.e(tag, "method ${call.method} failed", t)
            ERROR to t.message
        }
        main.post {
            when (reply) {
                NOT_IMPLEMENTED -> result.notImplemented()
                is Pair<*, *> -> result.error(ERROR, reply.second as? String, null)
                else -> result.success(reply)
            }
        }
    }

    // ─── §8 device / network info ─────────────────────────────────────────────

    private fun getIpAddress(): String {
        try {
            for (nif in NetworkInterface.getNetworkInterfaces()) {
                for (addr in nif.inetAddresses) {
                    if (!addr.isLoopbackAddress && addr is Inet4Address) {
                        return addr.hostAddress ?: "Unknown"
                    }
                }
            }
        } catch (t: Throwable) {
            Log.e(tag, "getIpAddress failed", t)
        }
        return "Unknown"
    }

    private fun getMacAddress(): String {
        macFromInterface("eth0")?.let { return it }
        macFromInterface("wlan0")?.let { return it }
        for (path in arrayOf("/sys/class/net/eth0/address", "/sys/class/net/wlan0/address")) {
            try {
                val f = File(path)
                if (f.exists()) {
                    val a = f.readText().trim().uppercase(Locale.US)
                    if (a.isNotEmpty() && a != "00:00:00:00:00:00") return a
                }
            } catch (_: Throwable) {
            }
        }
        return "Unavailable"
    }

    private fun macFromInterface(name: String): String? {
        return try {
            val mac = NetworkInterface.getByName(name)?.hardwareAddress ?: return null
            val hex = mac.joinToString(":") { String.format("%02X", it) }
            if (hex != "00:00:00:00:00:00") hex else null
        } catch (_: Throwable) {
            null
        }
    }

    private fun getCpuSerial(): String {
        try {
            val f = File("/proc/cpuinfo")
            if (f.exists()) {
                f.bufferedReader().useLines { lines ->
                    lines.forEach { line ->
                        if (line.contains("Serial", ignoreCase = true)) {
                            val parts = line.split(":")
                            if (parts.size > 1) return parts[1].trim()
                        }
                    }
                }
            }
        } catch (t: Throwable) {
            Log.e(tag, "getCpuSerial failed", t)
        }
        return "Unavailable"
    }

    private fun getConnectionType(): String {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return "Disconnected"
        val active = cm.activeNetwork ?: return "Disconnected"
        val caps = cm.getNetworkCapabilities(active) ?: return "Disconnected"
        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Cellular"
            else -> "Other"
        }
    }

    private val suBinaryPaths = listOf(
        "/system/bin/su", "/system/xbin/su", "/su/bin/su", "/sbin/su",
        "/vendor/bin/su", "/system/sbin/su", "/magisk/.core/bin/su",
        "/debug_ramdisk/su"
    )

    /**
     * Root detection. `which su` alone gives false negatives on boxes where the
     * su binary isn't on PATH (common on Rockchip), so check known locations
     * first, then `which`, then actually try to open a root shell (`id`).
     */
    private fun isRootAvailable(): Boolean {
        if (suBinaryPaths.any { File(it).exists() }) return true
        try {
            if (Runtime.getRuntime().exec(arrayOf("which", "su")).waitFor() == 0) return true
        } catch (_: Throwable) {
        }
        return rootIdOutput().contains("uid=0")
    }

    /** Runs `id` through su and returns its output (uid=0(root)…), or "" if root
     *  isn't granted/available. Used for diagnostics — surfaces WHY root fails. */
    private fun rootIdOutput(): String = runSuCapture("id").output

    // ─── §7 timezone sync ─────────────────────────────────────────────────────

    /**
     * Detects the timezone from public-IP geolocation and, if root is available,
     * sets the system timezone. Returns the detected timezone id, or null.
     */
    private fun syncTimezone(): String? {
        val tz = fetchTimezoneFromInternet() ?: return null
        try {
            if (isRootAvailable()) {
                val code = runSu(
                    "setprop persist.sys.timezone $tz",
                    "am broadcast -a android.intent.action.TIMEZONE_CHANGED --es time-zone $tz"
                )
                Log.d(tag, "syncTimezone set $tz via root, exit=$code")
            } else {
                Log.w(tag, "syncTimezone: root unavailable, detected $tz (not applied)")
            }
        } catch (t: Throwable) {
            Log.e(tag, "syncTimezone apply failed", t)
        }
        return tz
    }

    private fun fetchTimezoneFromInternet(): String? {
        data class Provider(val url: String, val parse: (String) -> String?)
        val providers = listOf(
            Provider("https://ipapi.co/json/") {
                JSONObject(it).optString("timezone").takeIf { s -> s.isNotBlank() }
            },
            Provider("https://ipwho.is/") {
                val root = JSONObject(it)
                root.optJSONObject("timezone")?.optString("id")?.takeIf { s -> s.isNotBlank() }
                    ?: root.optString("timezone").takeIf { s -> s.isNotBlank() }
            },
            Provider("https://worldtimeapi.org/api/ip") {
                JSONObject(it).optString("timezone").takeIf { s -> s.isNotBlank() }
            }
        )
        for (p in providers) {
            try {
                val body = httpGet(p.url)
                val tz = p.parse(body)
                if (!tz.isNullOrBlank()) {
                    Log.d(tag, "timezone from ${p.url}: $tz")
                    return tz
                }
            } catch (t: Throwable) {
                Log.w(tag, "timezone provider failed: ${p.url}", t)
            }
        }
        return null
    }

    private fun httpGet(url: String): String {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 7000
            readTimeout = 7000
            requestMethod = "GET"
            setRequestProperty("Accept", "application/json")
            setRequestProperty("User-Agent", "FNDTV/1.0 (Android)")
        }
        try {
            if (conn.responseCode !in 200..299) {
                throw IllegalStateException("HTTP ${conn.responseCode} from $url")
            }
            return conn.inputStream.bufferedReader().use { it.readText() }
        } finally {
            conn.disconnect()
        }
    }

    // ─── §6 power ─────────────────────────────────────────────────────────────

    /** Puts the box into standby via root (KEYCODE_SLEEP). */
    private fun sleep(): Boolean = runSu("input keyevent 223") == 0

    /** Reboots the box — DevicePolicyManager if device-owner, else root. */
    private fun reboot(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isDeviceOwner()) {
            try {
                val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                dpm.reboot(adminComponent())
                return true
            } catch (t: Throwable) {
                Log.w(tag, "DPM reboot failed, falling back to root", t)
            }
        }
        return runSu("reboot") == 0
    }

    // ─── §1 kiosk ─────────────────────────────────────────────────────────────

    private fun adminComponent(): ComponentName =
        ComponentName(context, "${context.packageName}.MyDeviceAdminReceiver")

    private fun isDeviceOwner(): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
        return dpm?.isDeviceOwnerApp(context.packageName) == true
    }

    /**
     * When we're Device Owner, pins the HOME intent to this app at the framework
     * level via `addPersistentPreferredActivity`. This is the canonical, most
     * durable way to be the launcher — survives reboots and can't be changed by
     * the user (unlike root `set-home-activity`). No-op if not device-owner.
     */
    private fun setPersistentLauncher(): Boolean {
        if (!isDeviceOwner()) return false
        return try {
            val dpm =
                context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val filter = IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            val activity = ComponentName(context, "${context.packageName}.MainActivity")
            dpm.addPersistentPreferredActivity(adminComponent(), filter, activity)
            Log.d(tag, "setPersistentLauncher: DPM persistent HOME -> $activity")
            true
        } catch (t: Throwable) {
            Log.w(tag, "setPersistentLauncher failed", t)
            false
        }
    }

    private fun defaultLauncher(): String? {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return context.packageManager
            .resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            ?.activityInfo?.packageName
    }

    /**
     * Sets this app (MainActivity) as the default HOME launcher via root.
     * Disables the current competing launcher first (e.g. Google TV Home) so
     * `set-home-activity` actually sticks — the box-verified approach
     * (`pm disable-user --user 0 com.google.android.tvlauncher`). Disabling
     * (not uninstalling) is safer for a system launcher and reversible.
     */
    private fun setDefaultLauncher(): Boolean {
        val myPkg = context.packageName
        val component = "$myPkg/$myPkg.MainActivity"

        val current = defaultLauncher()
        val protectedPkgs =
            setOf("android", "com.android.systemui", "com.android.settings", myPkg)
        if (current != null && current !in protectedPkgs) {
            val disabled = disablePackage(current)
            Log.d(tag, "setDefaultLauncher: competing launcher=$current disabled=$disabled")
        }

        val code = runSu(
            "cmd package set-home-activity $component",
            "pm set-home-activity $component"
        )
        val ok = code == 0 || defaultLauncher() == myPkg
        Log.d(tag, "setDefaultLauncher: component=$component exit=$code -> $ok")
        return ok
    }

    /**
     * Grants this app Device Owner via root, first deactivating/uninstalling any
     * other active admins (protecting core system packages). Ported faithfully
     * from the reference launcher.
     */
    private fun setupDeviceOwner(): Boolean {
        if (isDeviceOwner()) return true
        val pkg = context.packageName
        val admin = "$pkg/$pkg.MyDeviceAdminReceiver"
        val script = """
            APP_PKG='$pkg'
            ADMIN='$admin'
            dpm list-active-admins 2>/dev/null | while read -r line; do
                clean=${'$'}(echo "${'$'}line" | sed 's/.*ComponentInfo{//;s/}.*//;s/.*admin=//;s/^[[:space:]]*//;s/[[:space:]]*${'$'}//')
                [ -z "${'$'}clean" ] && continue
                pkg=${'$'}{clean%%/*}
                if [ "${'$'}pkg" != "${'$'}APP_PKG" ] && [ "${'$'}pkg" != "android" ] && [ "${'$'}pkg" != "com.android.settings" ] && [ "${'$'}pkg" != "com.android.systemui" ]; then
                    dpm remove-active-admin --user 0 "${'$'}clean" 2>&1 || dpm remove-active-admin "${'$'}clean" 2>&1
                    pm uninstall --user 0 "${'$'}pkg" 2>&1 || pm uninstall "${'$'}pkg" 2>&1
                fi
            done
            dpm set-device-owner --user 0 "${'$'}ADMIN" 2>&1 || dpm set-device-owner "${'$'}ADMIN" 2>&1
        """.trimIndent()
        val result = runSuCapture(script)
        val ok = isDeviceOwner()
        // dpm's own message is the answer when this fails, e.g. "Not allowed to
        // set the device owner because there are already several users on the
        // device" / "already has a device owner" — log it verbatim.
        Log.i(
            tag,
            "setupDeviceOwner -> $ok (exit=${result.exitCode})\n${result.output.take(1200)}"
        )
        lastDeviceOwnerOutput = result.output.take(400)
        return ok
    }

    /** Last `dpm set-device-owner` output, surfaced in the maintenance summary. */
    private var lastDeviceOwnerOutput: String = ""

    /** Uninstalls each package via root; returns those actually removed. */
    private fun uninstallPackages(packages: List<String>): List<String> {
        val removed = mutableListOf<String>()
        for (p in packages) {
            if (p.isBlank() || p == context.packageName) continue
            // Do NOT pre-check with our PackageManager: Android 11+ package
            // visibility hides other apps from us (no <queries>/QUERY_ALL_PACKAGES),
            // so getPackageInfo throws NotFound and we'd wrongly skip installed
            // apps. Root's shell sees everything — run pm uninstall and trust its
            // "Success"/"Failure" output. (`-k --user 0` first: keeps data / works
            // for system apps; then fallbacks.)
            val res = runSuCapture(
                "pm uninstall -k --user 0 $p",
                "pm uninstall $p",
                "pm uninstall --user 0 $p"
            )
            Log.d(tag, "uninstall $p -> exit=${res.exitCode} out=[${res.output.take(200)}]")
            if (res.output.contains("Success", ignoreCase = true)) removed.add(p)
        }
        return removed
    }

    /**
     * Disables (does NOT uninstall) components/packages that can't be removed
     * but should be blocked — e.g. the TV Settings activity so the remote can't
     * open system settings. `component` targets are `pkg/.Activity`; `package`
     * targets are a bare package name.
     */
    private fun disableComponent(component: String): Boolean =
        runSu(
            "pm disable --user 0 $component",
            "pm disable-user --user 0 $component"
        ) == 0

    private fun disablePackage(pkg: String): Boolean =
        runSu(
            "pm disable-user --user 0 $pkg",
            "pm disable $pkg"
        ) == 0

    /** Enables ADB-over-TCP only for privileged roles; disables otherwise. */
    private fun configureAdbTcp(user: String?): Boolean {
        val normalized = user?.trim()?.lowercase()
        val enable = normalized != null && normalized in adbTcpAllowedUsers
        val port = if (enable) "5555" else "-1"
        val cmds = adbTcpPortProperties.map { "setprop $it $port" } + listOf("stop adbd", "start adbd")
        return runSu(*cmds.toTypedArray()) == 0
    }

    /**
     * Boot-time maintenance sequence: device-owner provisioning, default-launcher
     * takeover, unwanted-app removal (uninstall), and disabling of components /
     * packages that can't be removed (e.g. system settings). Returns a summary
     * map. No-op without root.
     */
    private fun runStartupMaintenance(
        unwantedApps: List<String>,
        disabledComponents: List<String>,
        disabledPackages: List<String>
    ): Map<String, Any?> {
        val summary = mutableMapOf<String, Any?>()
        val rooted = isRootAvailable()
        summary["root"] = rooted
        // Surface exactly what the root shell reports — makes box logs conclusive
        // (e.g. empty/uid!=0 means su exists but wasn't granted to this package).
        val rootId = rootIdOutput()
        summary["rootId"] = rootId
        Log.i(tag, "runStartupMaintenance: root=$rooted id=[$rootId]")
        if (!rooted) {
            Log.w(tag, "runStartupMaintenance: root unavailable, skipping")
            return summary
        }
        summary["deviceOwner"] = if (isDeviceOwner()) true else setupDeviceOwner()
        if (summary["deviceOwner"] != true && lastDeviceOwnerOutput.isNotEmpty()) {
            summary["deviceOwnerError"] = lastDeviceOwnerOutput
        }
        summary["launcherBefore"] = defaultLauncher()
        summary["launcherSet"] =
            if (defaultLauncher() == context.packageName) true else setDefaultLauncher()
        // Device-owner framework lock for HOME (durable; survives reboot).
        summary["persistentLauncher"] = setPersistentLauncher()
        summary["launcherAfter"] = defaultLauncher()
        summary["removed"] = uninstallPackages(unwantedApps)
        summary["disabledComponents"] =
            disabledComponents.filter { it.isNotBlank() && disableComponent(it) }
        summary["disabledPackages"] =
            disabledPackages.filter { it.isNotBlank() && disablePackage(it) }
        Log.i(tag, "runStartupMaintenance -> $summary")
        return summary
    }

    // ─── network manager (device-owner APIs primary, root shell fallback) ────

    private val wifi: WifiManager?
        get() = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager

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

    /** One scan result carried internally before it's mapped to a channel reply. */
    private data class ScanNet(
        val ssid: String,
        val secured: Boolean,
        val rssi: Int,
        val security: String
    )

    /**
     * Classifies a scan result's `capabilities` string into the security type
     * the join path acts on: `open`, `wpa2` (also WEP/EAP best-effort), or
     * `wpa3`. WPA3 is reported ONLY for SAE-required APs (SAE present, PSK
     * absent); WPA2/WPA3 transition-mode APs advertise both and join over the
     * PSK path, so they're reported as `wpa2`.
     */
    private fun classifySecurity(capabilities: String): String = when {
        capabilities.contains("SAE") && !capabilities.contains("PSK") -> "wpa3"
        capabilities.contains("PSK") || capabilities.contains("SAE") ||
            capabilities.contains("WPA") || capabilities.contains("WEP") ||
            capabilities.contains("EAP") -> "wpa2"
        else -> "open"
    }

    /**
     * Scan for networks. Primary: WifiManager (location self-granted via root).
     * Fallback: `cmd wifi list-scan-results` (A11+). Returns a list of
     * {ssid, secured, rssi, security} deduped by ssid (strongest kept).
     */
    private fun scanWifi(): List<Map<String, Any?>> {
        if (isRootAvailable()) {
            runSu(
                "pm grant ${context.packageName} android.permission.ACCESS_FINE_LOCATION",
                "pm grant ${context.packageName} android.permission.NEARBY_WIFI_DEVICES"
            )
        }
        val results = mutableListOf<ScanNet>()
        try {
            val w = wifi
            @Suppress("DEPRECATION") w?.startScan()
            Thread.sleep(2500) // give the chip a beat; cached results are fine too
            @Suppress("DEPRECATION")
            w?.scanResults?.forEach { r ->
                val ssid = r.SSID?.takeIf { it.isNotBlank() } ?: return@forEach
                val security = classifySecurity(r.capabilities)
                results.add(ScanNet(ssid, security != "open", r.level, security))
            }
        } catch (t: Throwable) {
            Log.w(tag, "WifiManager scan failed", t)
        }
        if (results.isEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && isRootAvailable()) {
            // Header: "BSSID  Frequency  RSSI  Age(sec)  SSID  Flags"
            val out = runSuCapture("cmd wifi start-scan", "sleep 3", "cmd wifi list-scan-results").output
            val lineRegex = Regex(
                "^\\s*([0-9a-fA-F:]{17})\\s+\\S+\\s+(-?\\d+).*?\\s{2,}(\\S.*?)\\s{2,}(\\[.*)?$"
            )
            for (line in out.lines().drop(1)) {
                val m = lineRegex.find(line) ?: continue
                val rssi = m.groupValues[2].toIntOrNull() ?: continue
                val ssid = m.groupValues[3].trim()
                if (ssid.isBlank()) continue
                val security = classifySecurity(m.groupValues[4])
                results.add(ScanNet(ssid, security != "open", rssi, security))
            }
        }
        return results
            .groupBy { it.ssid }
            .map { (_, group) -> group.maxBy { it.rssi } }
            .sortedByDescending { it.rssi }
            .map {
                mapOf(
                    "ssid" to it.ssid,
                    "secured" to it.secured,
                    "rssi" to it.rssi,
                    "security" to it.security
                )
            }
    }

    /**
     * Join a network. Primary: legacy WifiConfiguration add/enable — still
     * honoured for device-owner apps on API 29+ (and the only path on the
     * Android 10 X88 Pro 10 fleet). Fallback: `cmd wifi connect-network` (A11+).
     * [security] is `open`/`wpa2`/`wpa3` (from the scan); WPA3 uses SAE key
     * management, which the legacy WifiConfiguration path supports only on
     * API 30+ — an SAE-only AP on an unrooted Android-10 box can't be joined and
     * surfaces as the usual timeout. Returns true when the join was INITIATED;
     * Dart polls wifiStatus for the outcome (a wrong password only shows as a
     * timeout).
     */
    private fun connectWifi(ssid: String, password: String?, security: String?): Boolean {
        if (ssid.isBlank()) return false
        val wantsWpa3 = security == "wpa3"
        try {
            val w = wifi ?: throw IllegalStateException("no WifiManager")
            @Suppress("DEPRECATION")
            if (w.isWifiEnabled == false) w.isWifiEnabled = true
            @Suppress("DEPRECATION")
            val conf = WifiConfiguration().apply {
                SSID = "\"$ssid\""
                when {
                    password.isNullOrEmpty() ->
                        allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
                    wantsWpa3 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                        // WPA3-Personal (SAE). KeyMgmt.SAE is API 30+; the
                        // framework enforces the required Protected Management
                        // Frames for SAE automatically.
                        allowedKeyManagement.set(WifiConfiguration.KeyMgmt.SAE)
                        preSharedKey = "\"$password\""
                    }
                    else -> preSharedKey = "\"$password\"" // WPA2-PSK
                }
            }
            @Suppress("DEPRECATION")
            val netId = w.addNetwork(conf)
            if (netId >= 0) {
                @Suppress("DEPRECATION") w.disconnect()
                @Suppress("DEPRECATION") w.enableNetwork(netId, true)
                @Suppress("DEPRECATION") w.reconnect()
                Log.i(tag, "connectWifi: legacy path initiated for $ssid (netId=$netId, sec=$security)")
                return true
            }
            Log.w(tag, "connectWifi: addNetwork returned $netId for $ssid")
        } catch (t: Throwable) {
            Log.w(tag, "connectWifi legacy path failed", t)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && isRootAvailable()) {
            val esc = ssid.replace("'", "'\\''")
            val cmd = when {
                password.isNullOrEmpty() -> "cmd wifi connect-network '$esc' open"
                else -> "cmd wifi connect-network '$esc' ${if (wantsWpa3) "wpa3" else "wpa2"} " +
                    "'${password.replace("'", "'\\''")}'"
            }
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

    // ─── root helper ──────────────────────────────────────────────────────────

    private data class SuResult(val exitCode: Int, val output: String)

    /**
     * Runs commands through a root shell, draining stdout+stderr.
     *
     * Draining matters twice over: a chatty script (dpm/pm) can fill the pipe
     * buffer and block `waitFor()` forever if nobody reads it, and the output is
     * the only way to see WHY a command failed (e.g. dpm refusing device-owner).
     */
    private fun runSuCapture(vararg commands: String): SuResult {
        return try {
            val process = Runtime.getRuntime().exec("su")
            val out = StringBuilder()
            val tOut = Thread {
                process.inputStream.bufferedReader()
                    .forEachLine { synchronized(out) { out.append(it).append('\n') } }
            }
            val tErr = Thread {
                process.errorStream.bufferedReader()
                    .forEachLine { synchronized(out) { out.append(it).append('\n') } }
            }
            tOut.start()
            tErr.start()
            DataOutputStream(process.outputStream).use { os ->
                commands.forEach { os.writeBytes(it + "\n") }
                os.writeBytes("exit\n")
                os.flush()
            }
            val code = process.waitFor()
            tOut.join(2000)
            tErr.join(2000)
            SuResult(code, synchronized(out) { out.toString().trim() })
        } catch (t: Throwable) {
            Log.e(tag, "runSu failed", t)
            SuResult(-1, t.message ?: "")
        }
    }

    private fun runSu(vararg commands: String): Int {
        val result = runSuCapture(*commands)
        Log.d(
            tag,
            "su(${commands.firstOrNull()?.take(60)}) exit=${result.exitCode} " +
                "out=[${result.output.take(400)}]"
        )
        return result.exitCode
    }

    companion object {
        private const val NOT_IMPLEMENTED = "__not_implemented__"
        private const val ERROR = "stb_error"
    }
}
