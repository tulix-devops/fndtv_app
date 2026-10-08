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
import java.util.concurrent.atomic.AtomicInteger

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
                "homeCandidates" -> homeCandidates()
                "kioskDiagnostics" -> kioskDiagnostics()
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

    /** Set once a root shell has actually been granted. Negatives are never
     *  cached: a grant can arrive later in the boot, and the guard retries. */
    @Volatile
    private var rootGranted: Boolean = false

    /**
     * Root detection — a GRANTED root shell, not a binary on disk.
     *
     * This used to return true the moment it found `/system/bin/su`. These boxes
     * ship that binary whether or not the superuser layer will hand it to *us*,
     * so a box that denied every single command still reported `root=true`. The
     * maintenance summary then showed a pile of independent failures with
     * nothing tying them together, when the cause was one thing for all of them.
     *
     * The only honest test is to open a root shell and look at the uid.
     */
    private fun isRootAvailable(): Boolean {
        if (rootGranted) return true
        val out = rootIdOutput()
        val granted = out.contains("uid=0")
        if (granted) {
            rootGranted = true
        } else {
            Log.w(
                tag,
                "root NOT granted — su binary on disk=${suBinaryPaths.any { File(it).exists() }}, " +
                    "id=[${out.take(200)}]"
            )
        }
        return granted
    }

    /** Runs `id` through su and returns its output (uid=0(root)…), or "" if root
     *  isn't granted/available. Used for diagnostics — surfaces WHY root fails. */
    private fun rootIdOutput(): String = runSuCapture("id").output

    // ─── §7 timezone sync ─────────────────────────────────────────────────────

    /** A resolved zone: IANA id plus the CURRENT offset from UTC, in seconds. */
    private data class Zone(val id: String, val offsetSeconds: Int)

    /**
     * Detects the box's timezone from public-IP geolocation and, when root
     * allows, applies it to the system. Returns `{id, offsetSeconds, applied}`,
     * or null when nothing could be resolved (offline).
     *
     * The OFFSET is the point of this, not the id. Applying the zone needs root
     * (`setprop persist.sys.timezone`), and on boxes where `su` is refused the
     * system zone stays wrong forever — every schedule time then renders through
     * a `.toLocal()` that is an hour or two out, which is the EPG being "off".
     * Handing the offset to Dart lets the app render correct local times on a
     * box whose system zone we are never allowed to fix.
     */
    private fun syncTimezone(): Map<String, Any?>? {
        val zone = fetchTimezoneFromInternet() ?: return null
        var applied = false
        try {
            if (isRootAvailable()) {
                val code = runSu(
                    "setprop persist.sys.timezone ${zone.id}",
                    "am broadcast -a android.intent.action.TIMEZONE_CHANGED --es time-zone ${zone.id}"
                )
                applied = code == 0
                Log.d(tag, "syncTimezone set ${zone.id} via root, exit=$code")
            } else {
                Log.w(tag, "syncTimezone: no root — detected ${zone.id} " +
                    "(offset ${zone.offsetSeconds}s), NOT applied to the system; " +
                    "the app renders through the offset instead")
            }
        } catch (t: Throwable) {
            Log.e(tag, "syncTimezone apply failed", t)
        }
        return mapOf(
            "id" to zone.id,
            "offsetSeconds" to zone.offsetSeconds,
            "applied" to applied,
        )
    }

    /**
     * Parses "+02:00" / "+0200" / "0200" into seconds. Providers disagree on the
     * format, and getting this wrong is a silent one-hour EPG error rather than
     * a visible failure — so unparseable input returns null and we fall through
     * to the next provider instead of guessing zero.
     */
    private fun parseUtcOffset(raw: String?): Int? {
        val s = raw?.trim()?.replace(":", "") ?: return null
        val m = Regex("^([+-])?(\\d{2})(\\d{2})$").find(s) ?: return null
        val (sign, h, min) = m.destructured
        val seconds = h.toInt() * 3600 + min.toInt() * 60
        return if (sign == "-") -seconds else seconds
    }

    private fun fetchTimezoneFromInternet(): Zone? {
        data class Provider(val url: String, val parse: (String) -> Zone?)
        val providers = listOf(
            Provider("https://ipapi.co/json/") {
                val root = JSONObject(it)
                val id = root.optString("timezone").takeIf { s -> s.isNotBlank() }
                val off = parseUtcOffset(root.optString("utc_offset"))
                if (id != null && off != null) Zone(id, off) else null
            },
            Provider("https://ipwho.is/") {
                val root = JSONObject(it)
                val tzObj = root.optJSONObject("timezone")
                val id = tzObj?.optString("id")?.takeIf { s -> s.isNotBlank() }
                    ?: root.optString("timezone").takeIf { s -> s.isNotBlank() }
                // ipwho.is gives the offset in seconds directly.
                val off = tzObj?.let { o ->
                    if (o.has("offset")) o.optInt("offset") else parseUtcOffset(o.optString("utc"))
                }
                if (id != null && off != null) Zone(id, off) else null
            },
            Provider("https://worldtimeapi.org/api/ip") {
                val root = JSONObject(it)
                val id = root.optString("timezone").takeIf { s -> s.isNotBlank() }
                // raw_offset excludes DST; dst_offset carries it.
                val off = if (root.has("raw_offset")) {
                    root.optInt("raw_offset") + root.optInt("dst_offset", 0)
                } else {
                    parseUtcOffset(root.optString("utc_offset"))
                }
                if (id != null && off != null) Zone(id, off) else null
            }
        )
        for (p in providers) {
            try {
                val zone = p.parse(httpGet(p.url))
                if (zone != null) {
                    Log.d(tag, "timezone from ${p.url}: ${zone.id} (${zone.offsetSeconds}s)")
                    return zone
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
     * Packages that must never be uninstalled or disabled, whatever they
     * declare. `com.android.settings` is on the list because it hosts
     * `FallbackHome` — the activity the framework falls back to when no real
     * launcher resolves. Disable it and a box with no other launcher has
     * nothing at all to show.
     */
    private val protectedPackages: Set<String>
        get() = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.android.tv.settings",
            "com.android.provision",
            context.packageName,
        )

    /**
     * Every OTHER package that can currently answer the HOME intent — i.e. every
     * app that can appear in the "Use ___ as Home" chooser and steal the box.
     *
     * Discovered, not listed. A static list only ever covered the launchers we
     * happened to have seen (SmartLauncher, Google TV Home); firmware batches
     * ship others, and the one we do not know about is exactly the one that wins
     * the chooser. Disabled packages do not resolve, so an empty result is the
     * precise definition of "nothing can take HOME from us".
     *
     * Read twice: PackageManager (subject to Android 11 package visibility, hence
     * the `<queries>` block in the manifest) and, when we have it, the root shell,
     * which sees everything regardless. The union is what we act on.
     */
    private fun homeCandidates(useRoot: Boolean = isRootAvailable()): List<String> {
        val found = LinkedHashSet<String>()

        try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            context.packageManager.queryIntentActivities(intent, 0).forEach {
                val info = it.activityInfo ?: return@forEach
                // FallbackHome is the framework's own no-launcher placeholder,
                // not a competitor — and it lives in a protected package anyway.
                if (info.name?.contains("FallbackHome") == true) return@forEach
                found += info.packageName
            }
        } catch (t: Throwable) {
            Log.w(tag, "homeCandidates: queryIntentActivities failed", t)
        }

        if (useRoot) {
            val out = runSuCapture(
                "cmd package query-activities -a android.intent.action.MAIN " +
                    "-c android.intent.category.HOME --user 0",
                "pm query-activities -a android.intent.action.MAIN " +
                    "-c android.intent.category.HOME",
            ).output
            // Both `packageName=<pkg>` (verbose form) and `<pkg>/<class>` (brief
            // form) appear depending on the Android version on the box.
            Regex("packageName=([A-Za-z0-9_.]+)").findAll(out)
                .forEach { found += it.groupValues[1] }
            Regex("(?m)^\\s*([A-Za-z0-9_.]+)/[A-Za-z0-9_.]+\\s*$").findAll(out)
                .forEach { found += it.groupValues[1] }
        }

        val protectedPkgs = protectedPackages
        return found.filter { it.isNotBlank() && it !in protectedPkgs }
    }

    /**
     * Points the HOME intent at this app.
     *
     * Deliberately does NOT touch the competing launchers any more — that has to
     * happen BEFORE this runs, not after. Android drops a preferred-activity
     * record as soon as the set of activities matching the intent differs from
     * the set recorded when the preference was written, so uninstalling or
     * disabling a launcher after calling `set-home-activity` invalidates the very
     * preference it just wrote. That was the boot-to-boot oscillation: pinned on
     * one boot, chooser on the next.
     */
    private fun setDefaultLauncher(): Boolean {
        val myPkg = context.packageName
        val component = "$myPkg/$myPkg.MainActivity"
        val res = runSuCapture(
            // Android 10+ (and decisively by 12+) the default launcher is owned
            // by RoleManager, NOT by the preferred-activity table. On a box
            // whose firmware already installed its own launcher as the HOME
            // role holder there is no preference to win and no chooser to
            // answer — the incumbent has to be replaced. This is the lever that
            // does that; `set-home-activity` alone left an Android 14 box
            // booting straight into its stock launcher.
            "cmd role add-role-holder android.app.role.HOME $myPkg",
            "cmd role add-role-holder --user 0 android.app.role.HOME $myPkg",
            // Pre-role boxes (and belt-and-braces everywhere else).
            "cmd package set-home-activity $component",
            "pm set-home-activity $component",
        )
        val ok = defaultLauncher() == myPkg
        Log.d(
            tag,
            "setDefaultLauncher: component=$component -> $ok " +
                "out=[${res.output.take(300)}]"
        )
        return ok
    }

    /** Current holder of `android.app.role.HOME`, or null. Diagnostic only. */
    private fun homeRoleHolder(): String? {
        val out = runSuCapture("cmd role get-role-holders android.app.role.HOME").output
        return out.lineSequence()
            .map { it.trim() }
            .firstOrNull { it.isNotEmpty() && it.contains('.') && !it.contains(' ') }
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

    /**
     * Whether [pkg] can still run for user 0 — installed AND not disabled.
     *
     * Read through root, never through our own PackageManager: Android 11
     * package visibility hides almost everything from us, so a NameNotFound
     * there would read as "already gone" and we would report removals that never
     * happened. `pm list packages` filters by substring, so the match is made
     * line-exact — otherwise `com.google.android.youtube` also matches
     * `com.google.android.youtube.tv` and one of them is never touched.
     */
    private fun isPackageActive(pkg: String): Boolean {
        val res = runSuCapture(
            "pm list packages --user 0 $pkg",
            "echo $MARKER",
            "pm list packages -d --user 0 $pkg",
        )
        val parts = res.output.split(MARKER)
        fun listed(block: String?) =
            block?.lineSequence()?.any { it.trim() == "package:$pkg" } == true
        return listed(parts.getOrNull(0)) && !listed(parts.getOrNull(1))
    }

    /**
     * Makes [pkg] stop existing for user 0, as durably as root allows.
     *
     * Two levers, because neither alone is enough on these boxes:
     *  - `pm uninstall --user 0` removes a preinstalled app for the current user
     *    while the APK stays on /system (so a factory reset restores it). Some
     *    firmware marks packages non-removable and refuses.
     *  - `pm disable-user --user 0` cannot be refused, survives a reboot, and is
     *    undone with a single `pm enable`.
     *
     * [preferDisable] picks the order. Competing launchers take the reversible
     * route — disabling already stops them resolving HOME, which is all we need,
     * and leaves the box's own launcher recoverable. The unwanted-app list is
     * meant to be gone, so it uninstalls first.
     *
     * Returns "uninstalled" | "disabled" | "absent" | "failed".
     */
    private fun neutralizePackage(pkg: String, preferDisable: Boolean): String {
        if (pkg in protectedPackages) {
            Log.w(tag, "neutralize: refusing protected package $pkg")
            return "failed"
        }

        if (preferDisable && disablePackage(pkg)) {
            Log.d(tag, "neutralize $pkg -> disabled")
            return "disabled"
        }

        // `-k` keeps the data so a re-enabled package comes back configured.
        val res = runSuCapture(
            "pm uninstall -k --user 0 $pkg",
            "pm uninstall --user 0 $pkg",
            "pm uninstall $pkg",
        )
        if (res.output.contains("Success", ignoreCase = true)) {
            Log.d(tag, "neutralize $pkg -> uninstalled")
            return "uninstalled"
        }

        val outcome = when {
            !preferDisable && disablePackage(pkg) -> "disabled"
            !isPackageActive(pkg) -> "absent"
            else -> "failed"
        }
        Log.d(
            tag,
            "neutralize $pkg -> $outcome (uninstall out=[${res.output.take(160)}])"
        )
        return outcome
    }

    /**
     * Neutralises every package in [packages]; returns pkg -> outcome.
     *
     * Checks before it writes, so a box that has already been cleaned costs one
     * `pm list` per package and no writes at all. The previous version re-ran six
     * uninstalls on every single boot, and each of those mutated the set of HOME
     * candidates — which is what kept invalidating the launcher preference.
     */
    private fun neutralizePackages(
        packages: List<String>,
        preferDisable: Boolean = false,
    ): Map<String, String> {
        val (installed, disabled) = packageState()
        // An empty snapshot means the read failed, not that the box has no
        // packages. Fall back to attempting each one rather than silently
        // reporting the whole list as already gone.
        val trusted = installed.isNotEmpty()
        val out = LinkedHashMap<String, String>()
        for (p in packages.distinct()) {
            if (p.isBlank() || p in protectedPackages) continue
            val active = !trusted || (p in installed && p !in disabled)
            out[p] = if (!active) "absent" else neutralizePackage(p, preferDisable)
        }
        return out
    }

    /**
     * One root read of what is installed and what is disabled for user 0.
     *
     * Taken once per pass rather than once per package: every [runSuCapture]
     * spawns a fresh `su`, and on a box that has already been cleaned this
     * snapshot is the only root work the removal step does at all.
     */
    private fun packageState(): Pair<Set<String>, Set<String>> {
        val res = runSuCapture(
            "pm list packages --user 0",
            "echo $MARKER",
            "pm list packages -d --user 0",
        )
        val parts = res.output.split(MARKER)
        fun parse(block: String?): Set<String> =
            block?.lineSequence()
                ?.map { it.trim() }
                ?.filter { it.startsWith("package:") }
                ?.map { it.removePrefix("package:").substringBefore(':') }
                ?.toSet()
                ?: emptySet()
        return parse(parts.getOrNull(0)) to parse(parts.getOrNull(1))
    }

    /** Channel entry point. Returns the packages this call actually changed. */
    private fun uninstallPackages(packages: List<String>): List<String> =
        neutralizePackages(packages)
            .filterValues { it == "uninstalled" || it == "disabled" }
            .keys.toList()

    /**
     * Disables (does NOT uninstall) a component that can't be removed but should
     * be blocked — e.g. the TV Settings activity, so the remote can't open
     * system settings. Targets are `pkg/.Activity`.
     *
     * Judged on `pm`'s own output, not on the exit code: [runSuCapture] reports
     * the status of the LAST command in the shell, so the primary command
     * succeeding was being masked by its own fallback failing right after it —
     * these read as failures while actually having worked.
     */
    private fun disableComponent(component: String): Boolean {
        val res = runSuCapture(
            "pm disable --user 0 $component",
            "pm disable-user --user 0 $component"
        )
        val ok = res.output.contains("new state: disabled", ignoreCase = true)
        Log.d(tag, "disableComponent $component -> $ok out=[${res.output.take(200)}]")
        return ok
    }

    /**
     * Disables [pkg] for user 0 — it stops resolving intents (HOME included) and
     * stays that way across reboots, and `pm enable` undoes it.
     *
     * Verified rather than inferred, for the exit-code reason in
     * [disableComponent], and re-checked against the package list when `pm` says
     * nothing useful.
     */
    private fun disablePackage(pkg: String): Boolean {
        if (pkg in protectedPackages) {
            Log.w(tag, "disablePackage: refusing protected package $pkg")
            return false
        }
        val res = runSuCapture(
            "pm disable-user --user 0 $pkg",
            "pm disable $pkg"
        )
        // "Package com.foo new state: disabled-user" — covers both spellings.
        val ok = res.output.contains("new state: disabled", ignoreCase = true) ||
            !isPackageActive(pkg)
        Log.d(tag, "disablePackage $pkg -> $ok out=[${res.output.take(200)}]")
        return ok
    }

    /** Enables ADB-over-TCP only for privileged roles; disables otherwise. */
    private fun configureAdbTcp(user: String?): Boolean {
        val normalized = user?.trim()?.lowercase()
        val enable = normalized != null && normalized in adbTcpAllowedUsers
        val port = if (enable) "5555" else "-1"
        val cmds = adbTcpPortProperties.map { "setprop $it $port" } + listOf("stop adbd", "start adbd")
        return runSu(*cmds.toTypedArray()) == 0
    }

    /**
     * Read-only snapshot of everything that decides whether the kiosk can work,
     * for display ON THE BOX.
     *
     * Exists because the field cannot always send us logs: a box in a customer's
     * home is not on adb, and "it did the same thing" is not a diagnosis. Every
     * value here is one the takeover depends on, so a photograph of this screen
     * is enough to say which step failed and why — and to tell whether the
     * boxes that misbehave differ from the ones that don't.
     *
     * Changes nothing. Safe to call at any time.
     */
    private fun kioskDiagnostics(): Map<String, Any?> {
        val rooted = isRootAvailable()
        return mapOf(
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "product" to Build.PRODUCT,
            "fingerprint" to Build.FINGERPRINT,
            "androidRelease" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT,
            // Whether a root shell was actually GRANTED — not whether the su
            // binary exists, which is what we used to report.
            "root" to rooted,
            "suBinaryPresent" to suBinaryPaths.any { File(it).exists() },
            "rootId" to rootIdOutput().take(200),
            "deviceOwner" to isDeviceOwner(),
            "defaultLauncher" to defaultLauncher(),
            "homeRoleHolder" to if (rooted) homeRoleHolder() else null,
            "homeCandidates" to homeCandidates(rooted),
            "timezone" to java.util.TimeZone.getDefault().id,
            "systemTime" to java.text.SimpleDateFormat(
                "yyyy-MM-dd HH:mm:ss Z", Locale.US
            ).format(java.util.Date()),
        )
    }

    /**
     * Boot-time kiosk sequence. THE ORDER IS THE WHOLE POINT.
     *
     * Clear the field first — every other HOME candidate, then the preinstalled
     * apps the box should not offer — and pin ourselves only once that set is
     * final. The previous order did the opposite: it wrote the HOME preference
     * and then uninstalled SmartLauncher and disabled Google TV Home, changing
     * the very set the preference had just been recorded against. Android
     * answers that by dropping the preference, so the box came up pinned on one
     * boot and on "Use ___ as Home" the next — and because the pin step was
     * skipped whenever the launcher already looked right, nothing ever put it
     * back. That is the oscillation the field is seeing.
     *
     * Reports what it achieved, not what it attempted. [kioskReady] is the retry
     * contract for the Dart side; [kioskDurable] says whether it will still hold
     * after the next reboot.
     */
    private fun runStartupMaintenance(
        unwantedApps: List<String>,
        disabledComponents: List<String>,
        disabledPackages: List<String>
    ): Map<String, Any?> {
        val summary = mutableMapOf<String, Any?>()
        val myPkg = context.packageName
        val rooted = isRootAvailable()
        summary["root"] = rooted
        // Surface exactly what the root shell reports — makes box logs conclusive
        // (e.g. empty/uid!=0 means su exists but wasn't granted to this package).
        val rootId = rootIdOutput()
        summary["rootId"] = rootId
        summary["sdk"] = Build.VERSION.SDK_INT
        summary["launcherBefore"] = defaultLauncher()
        summary["homeCandidatesBefore"] = homeCandidates(rooted)
        // Who owns android.app.role.HOME going in. On Android 10+ this, not the
        // preferred-activity table, is what decides the boot launcher — and a
        // box that boots straight into its stock launcher with NO chooser is a
        // box where the firmware already made that launcher the role holder.
        if (rooted) summary["homeRoleBefore"] = homeRoleHolder()
        Log.i(tag, "runStartupMaintenance: root=$rooted id=[$rootId] sdk=${Build.VERSION.SDK_INT}")

        // Device owner is the one pin the user cannot undo, and it needs neither
        // root nor any of the steps below — so it is attempted whatever else is
        // available. It only succeeds on a box that has not completed setup;
        // everywhere else the fallbacks below are all we have.
        val owner = if (isDeviceOwner()) true else if (rooted) setupDeviceOwner() else false
        summary["deviceOwner"] = owner
        if (!owner && lastDeviceOwnerOutput.isNotEmpty()) {
            summary["deviceOwnerError"] = lastDeviceOwnerOutput
        }

        if (rooted) {
            // 1. Clear the field. Competing launchers first — these are exactly
            //    what puts the HOME chooser on screen. Reversible route: a
            //    disabled launcher no longer resolves HOME, which is all we need.
            summary["homeNeutralized"] =
                neutralizePackages(homeCandidates(true), preferDisable = true)
            // 2. Then the preinstalled apps the box should not offer at all.
            summary["removed"] = neutralizePackages(unwantedApps)
            summary["disabledComponents"] =
                disabledComponents.filter { it.isNotBlank() && disableComponent(it) }
            // Kept as disable-only (not neutralize): this list is documented as
            // reversible — see kStbDisabledPackages.
            summary["disabledPackages"] =
                disabledPackages.filter { it.isNotBlank() && disablePackage(it) }
        } else {
            Log.w(tag, "runStartupMaintenance: no root — cannot clear competing launchers")
        }

        // 3. The candidate set is final. Pin now, so the preference is recorded
        //    against a set that is not about to change underneath it.
        summary["persistentLauncher"] = setPersistentLauncher()
        summary["launcherSet"] = if (rooted) setDefaultLauncher() else false

        // 4. Verify. Never report success from the fact that a command ran.
        val after = defaultLauncher()
        val remaining = homeCandidates(rooted)
        summary["launcherAfter"] = after
        summary["homeCandidatesAfter"] = remaining
        if (rooted) summary["homeRoleAfter"] = homeRoleHolder()
        val ready = after == myPkg
        summary["kioskReady"] = ready
        // Durable = nothing can take HOME back, either because the framework
        // holds it for us (device owner) or because no other candidate is left.
        summary["kioskDurable"] =
            ready && (summary["persistentLauncher"] == true || remaining.isEmpty())

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
     *
     * Secured networks are joined with **WPA2-PSK, pinned** — we deliberately do
     * NOT use WPA3-SAE. The target STB fleet's Broadcom/Rockchip Wi-Fi firmware
     * cannot do the Protected Management Frames that SAE requires, so if the
     * framework is allowed to negotiate (or picks SAE) on a WPA2/WPA3-transition
     * AP, the driver reports `fw doesn't support MFP` and the AP rejects the
     * association (`ASSOC-REJECT status_code=53`) BEFORE the password handshake
     * even starts — which looks like a wrong password but isn't. Pinning WPA_PSK
     * forces WPA2 on transition APs (the common home-router case), which the
     * firmware handles fine. Genuinely WPA3-only APs are unjoinable on this
     * firmware regardless. [security] is kept for logging only.
     *
     * Returns true when the join was INITIATED; Dart polls wifiStatus for the
     * outcome (a wrong password only shows as a timeout).
     */
    private fun connectWifi(ssid: String, password: String?, security: String?): Boolean {
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
                    // Pin WPA2-PSK so the framework never auto-upgrades to SAE on
                    // a transition AP (see the method doc — old fw can't do MFP).
                    allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK)
                    preSharedKey = "\"$password\""
                }
            }
            @Suppress("DEPRECATION")
            val netId = w.addNetwork(conf)
            if (netId >= 0) {
                @Suppress("DEPRECATION") w.disconnect()
                @Suppress("DEPRECATION") w.enableNetwork(netId, true)
                @Suppress("DEPRECATION") w.reconnect()
                Log.i(tag, "connectWifi: legacy WPA2-PSK path initiated for $ssid (netId=$netId, sec=$security)")
                return true
            }
            Log.w(tag, "connectWifi: addNetwork returned $netId for $ssid")
        } catch (t: Throwable) {
            Log.w(tag, "connectWifi legacy path failed", t)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && isRootAvailable()) {
            val esc = ssid.replace("'", "'\\''")
            // Always wpa2 (not wpa3) for the same firmware/MFP reason as above.
            val cmd = if (password.isNullOrEmpty()) {
                "cmd wifi connect-network '$esc' open"
            } else {
                "cmd wifi connect-network '$esc' wpa2 '${password.replace("'", "'\\''")}'"
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
            // Bounded wait. A superuser layer that answers a request with a
            // grant PROMPT leaves `su` hanging indefinitely when there is nobody
            // in front of the box — and this runs on a single-threaded executor,
            // so one hang wedges every kiosk, timezone and power call queued
            // behind it for the rest of the session.
            val code = AtomicInteger(-1)
            val waiter = Thread { code.set(runCatching { process.waitFor() }.getOrDefault(-1)) }
            waiter.start()
            waiter.join(SU_TIMEOUT_MS)
            if (waiter.isAlive) {
                Log.w(
                    tag,
                    "su TIMED OUT after ${SU_TIMEOUT_MS}ms (grant prompt with nobody to " +
                        "answer it?) — killing: ${commands.firstOrNull()?.take(60)}"
                )
                runCatching { process.destroy() }
                waiter.join(1000)
            }
            tOut.join(2000)
            tErr.join(2000)
            SuResult(code.get(), synchronized(out) { out.toString().trim() })
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

        /** Separates two command outputs inside one root shell session. */
        private const val MARKER = "__fndtv__"

        /** Ceiling on a single root shell. Generous for `pm` work, finite for a
         *  superuser prompt nobody is going to answer. */
        private const val SU_TIMEOUT_MS = 15_000L
    }
}
