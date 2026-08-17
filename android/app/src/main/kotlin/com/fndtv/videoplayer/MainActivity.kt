package com.fndtv.videoplayer

import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Must extend AudioServiceActivity (not FlutterActivity) so just_audio_background
// can attach the media session to the correct FlutterEngine.
class MainActivity : AudioServiceActivity() {

    private val deviceChannel = "com.fndtv.videoplayer/device"

    /** Kept so the async install outcome can be pushed back to Dart. */
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceChannel)
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSerialNumber" -> result.success(readSerialNumber())
                "getAndroidId" -> result.success(readAndroidId())
                "getWifiMac" -> result.success(readWifiMac())
                "openDateSettings" -> result.success(openDateSettings())
                "isHomeApp" -> result.success(isHomeApp())
                "canRequestHomeRole" -> result.success(canRequestHomeRole())
                "requestHomeRole" -> result.success(requestHomeRole())
                "isDeviceOwner" -> result.success(ApkInstaller(this).isDeviceOwner())
                "installApk" ->
                    result.success(installApk(call.argument<String>("path")))
                else -> result.notImplemented()
            }
        }
        registerStbBridgeIfPresent(flutterEngine)

        // Native SurfaceView video player. Registered for every flavor (the code
        // is flavor-agnostic); which builds actually instantiate it is decided in
        // Dart — see StbSurfacePlayer / VideoPlayerPage.
        flutterEngine.platformViewsController.registry.registerViewFactory(
            StbSurfacePlayerFactory.VIEW_TYPE,
            StbSurfacePlayerFactory(flutterEngine.dartExecutor.binaryMessenger),
        )
    }

    // The STB-only native bridge (device/network info, timezone, kiosk, power)
    // lives in the `stb` source set. Register it reflectively so the shared
    // MainActivity compiles for the `normal` flavor, where the class is absent.
    private fun registerStbBridgeIfPresent(flutterEngine: FlutterEngine) {
        try {
            val clazz = Class.forName("com.fndtv.videoplayer.StbBridge")
            val instance = clazz
                .getDeclaredConstructor(android.content.Context::class.java)
                .newInstance(applicationContext)
            clazz.getMethod("register", FlutterEngine::class.java)
                .invoke(instance, flutterEngine)
        } catch (_: ClassNotFoundException) {
            // `normal` flavor: no STB bridge, nothing to register.
        } catch (t: Throwable) {
            android.util.Log.w("MainActivity", "StbBridge registration failed", t)
        }
    }

    // Best-effort read of the hardware serial number. On a set-top box the app is
    // typically a privileged/system app, so Build.getSerial() (or the ro.serialno
    // system property) returns the real serial; on ordinary apps it throws or
    // returns "unknown", in which case we fall back through the alternatives.
    private fun readSerialNumber(): String? {
        try {
            val serial = Build.getSerial()
            if (isValid(serial)) return serial
        } catch (_: Throwable) {
        }

        // System properties commonly holding the serial on STB firmware.
        for (key in listOf("ro.serialno", "ro.boot.serialno", "gsm.serial")) {
            val value = systemProperty(key)
            if (isValid(value)) return value
        }

        @Suppress("DEPRECATION")
        if (isValid(Build.SERIAL)) return Build.SERIAL

        return null
    }

    // SSAID — the per-device id Android generates at first boot.
    //
    // Used to disambiguate boxes whose factory serial is NOT unique (batches of
    // these boxes ship with the SoC vendor's default `ro.serialno`, so several
    // report the same string and collapse onto one record on the backend).
    //
    // Chosen for its lifetime: it is scoped to our signing key and survives an
    // app uninstall/reinstall or a "clear data", and resets only on a factory
    // reset. App-local storage would not — Hive lives in app data, so a QA
    // sideload would silently mint a new identity.
    private fun readAndroidId(): String? = try {
        val id = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
        if (isValid(id)) id else null
    } catch (t: Throwable) {
        android.util.Log.w("MainActivity", "android_id read failed", t)
        null
    }

    // Best-effort read of the Wi-Fi hardware (MAC) address. On modern Android the
    // WifiManager returns the anonymised 02:00:00:00:00:00 to ordinary apps, so we
    // read the interface address directly — which works for a system/privileged
    // app on the set-top box. Prefer the Wi-Fi interface, then fall back to any
    // other interface so a box on ethernet (or the emulator) still yields a MAC.
    private fun readWifiMac(): String? {
        macFromSys("wlan0")?.let { return it }

        try {
            val interfaces =
                java.util.Collections.list(java.net.NetworkInterface.getNetworkInterfaces())

            // Prefer any Wi-Fi interface (wlan0, wlan1, ...).
            for (nif in interfaces) {
                if (nif.name.startsWith("wlan", ignoreCase = true)) {
                    macFromNif(nif)?.let { return it }
                }
            }
            // Otherwise the first non-loopback interface with a hardware address.
            for (nif in interfaces) {
                if (nif.isLoopback) continue
                macFromNif(nif)?.let { return it }
            }
        } catch (_: Throwable) {
        }

        return macFromSys("eth0")
    }

    private fun macFromSys(iface: String): String? = try {
        val addr = java.io.File("/sys/class/net/$iface/address").readText().trim()
        if (isValidMac(addr)) addr.uppercase() else null
    } catch (_: Throwable) {
        null
    }

    private fun macFromNif(nif: java.net.NetworkInterface): String? {
        val mac = nif.hardwareAddress ?: return null
        val hex = mac.joinToString(":") { String.format("%02X", it) }
        return if (isValidMac(hex)) hex else null
    }

    private fun isValidMac(mac: String?): Boolean =
        !mac.isNullOrBlank() && mac != "02:00:00:00:00:00"

    // Installs a downloaded APK.
    //
    // PackageInstaller first: on a device-owner box that installs silently, with
    // no "install unknown apps" prompt — a pushed update used to stall on that
    // prompt with nobody in front of the screen. It also reports WHY an install
    // failed, which ACTION_VIEW never could.
    //
    // ACTION_VIEW stays as the fallback for when a session cannot even be
    // created, so a box is never left with no way to update at all.
    private fun installApk(path: String?): Boolean {
        val started = ApkInstaller(this).install(path) { outcome, message ->
            runOnUiThread {
                channel?.invokeMethod(
                    "onInstallOutcome",
                    mapOf("outcome" to outcome, "message" to message),
                )
            }
        }
        if (started) return true
        android.util.Log.w("MainActivity", "session install unavailable — ACTION_VIEW")
        return installApkViaViewIntent(path)
    }

    // Legacy path. Requires REQUEST_INSTALL_PACKAGES and, on ordinary apps, the
    // user allowing "install unknown apps" for FNDTV.
    private fun installApkViaViewIntent(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        return try {
            val file = File(path)
            if (!file.exists()) return false
            val uri = FileProvider.getUriForFile(this, "$packageName.provider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (t: Throwable) {
            android.util.Log.e("MainActivity", "installApk failed", t)
            false
        }
    }

    // ─── HOME role ────────────────────────────────────────────────────────────
    //
    // The one way an ORDINARY app can become the launcher: no root, no device
    // owner. It matters because of what it writes.
    //
    // Picking FNDTV from the "Use ___ as Home" chooser sets a PREFERRED
    // ACTIVITY, and Android drops that record whenever the set of HOME
    // candidates changes — including when FNDTV itself is installed or updated.
    // A box logged exactly that: "Result set changed, dropping preferred
    // activity for Intent { act=MAIN cat=[HOME, DEFAULT] }", 12 ms after our own
    // APK finished installing. So every update puts the chooser back, which is
    // why "we choose Always and it keeps coming back".
    //
    // The ROLE is held by RoleManager, survives a package update, and is what we
    // actually want. Requesting it costs one system dialog and one confirmation.

    private fun isHomeApp(): Boolean = try {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        packageManager
            .resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY)
            ?.activityInfo?.packageName == packageName
    } catch (_: Throwable) {
        false
    }

    /** Whether this box can show the HOME role dialog at all (API 29+, and the
     *  role has to exist — some OEM images strip the role UI). */
    private fun canRequestHomeRole(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        return try {
            val rm = getSystemService(android.app.role.RoleManager::class.java)
            rm != null &&
                rm.isRoleAvailable(android.app.role.RoleManager.ROLE_HOME) &&
                !rm.isRoleHeld(android.app.role.RoleManager.ROLE_HOME)
        } catch (t: Throwable) {
            android.util.Log.w("MainActivity", "canRequestHomeRole failed", t)
            false
        }
    }

    /**
     * Shows the system "make FNDTV your Home app" dialog. Returns whether it was
     * launched — the answer arrives later, so callers re-check [isHomeApp].
     *
     * Falls back to the system Home-app settings screen when the role dialog is
     * unavailable, which still reaches the same setting in two more key presses
     * rather than leaving the technician with nothing.
     */
    private fun requestHomeRole(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val rm = getSystemService(android.app.role.RoleManager::class.java)
                if (rm != null &&
                    rm.isRoleAvailable(android.app.role.RoleManager.ROLE_HOME)
                ) {
                    startActivityForResult(
                        rm.createRequestRoleIntent(android.app.role.RoleManager.ROLE_HOME),
                        REQUEST_HOME_ROLE,
                    )
                    return true
                }
            } catch (t: Throwable) {
                android.util.Log.w("MainActivity", "requestHomeRole failed", t)
            }
        }
        return try {
            startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
            true
        } catch (t: Throwable) {
            android.util.Log.w("MainActivity", "ACTION_HOME_SETTINGS failed", t)
            false
        }
    }

    // Opens the system date/time settings so the user can correct the clock
    // (useful on a box whose time is wrong / not NTP-synced).
    private fun openDateSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_DATE_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun isValid(value: String?): Boolean =
        !value.isNullOrBlank() && !value.equals("unknown", ignoreCase = true)

    private companion object {
        /** Result code for the HOME role dialog. The outcome is read back by
         *  re-checking [isHomeApp], so nothing is done with it directly. */
        const val REQUEST_HOME_ROLE = 4711
    }

    private fun systemProperty(key: String): String? {
        return try {
            val clazz = Class.forName("android.os.SystemProperties")
            val get = clazz.getMethod("get", String::class.java)
            get.invoke(clazz, key) as? String
        } catch (_: Throwable) {
            null
        }
    }
}
