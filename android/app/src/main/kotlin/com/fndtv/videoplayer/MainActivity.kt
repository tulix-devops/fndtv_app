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
                "getWifiMac" -> result.success(readWifiMac())
                "openDateSettings" -> result.success(openDateSettings())
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
