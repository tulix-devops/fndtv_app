package com.fndtv.videoplayer

import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import androidx.core.content.ContextCompat
import java.io.File

/**
 * Installs an APK through [PackageInstaller] instead of firing an ACTION_VIEW
 * intent at the system installer.
 *
 * Why: ACTION_VIEW always routes through the user-facing installer, which is
 * gated on "install unknown apps" for this app. A pushed update therefore
 * stalled on a permission prompt nobody was in front of — QA hit exactly that
 * on a box. A session-based install needs no such prompt when the app holds
 * device-owner, which is how the STB fleet is provisioned.
 *
 * The second win is diagnostic. ACTION_VIEW told us only that the installer
 * *launched*; a session reports why it failed — [PackageInstaller.STATUS_FAILURE_CONFLICT]
 * for the downgrade case that left boxes silently stuck on an old build.
 *
 * Not device owner? The commit comes back as
 * [PackageInstaller.STATUS_PENDING_USER_ACTION] and we launch the confirmation
 * the system hands us, which lands on the old behaviour rather than failing.
 */
class ApkInstaller(context: Context) {

    /// Application context on purpose: the status broadcast can arrive after the
    /// activity is gone (an install tears the process down), and a receiver
    /// registered on a dead Activity never fires — which would strand the
    /// "Installing…" overlay until its timeout.
    private val context: Context = context.applicationContext

    companion object {
        private const val TAG = "ApkInstaller"
        private const val ACTION_INSTALL_STATUS =
            "com.fndtv.videoplayer.INSTALL_STATUS"

        /** Mirrors the Dart-side `StbInstallOutcome`. */
        const val RESULT_SUCCESS = "success"
        const val RESULT_FAILURE = "failure"
        const val RESULT_BLOCKED_DOWNGRADE = "blocked_downgrade"
        const val RESULT_BLOCKED_SIGNATURE = "blocked_signature"
        const val RESULT_BLOCKED_CONFLICT = "blocked_conflict"
        const val RESULT_ABORTED = "aborted"
        const val RESULT_PENDING_USER_ACTION = "pending_user_action"

        /**
         * STATUS_FAILURE_CONFLICT covers every "clashes with what is already
         * installed" case, so the code alone cannot tell a refused downgrade
         * from a signing-key mismatch — and those need completely different
         * fixes. The message text is the only thing that distinguishes them.
         */
        fun classifyConflict(message: String?): String {
            val m = message?.uppercase() ?: return RESULT_BLOCKED_CONFLICT
            return when {
                m.contains("VERSION_DOWNGRADE") -> RESULT_BLOCKED_DOWNGRADE
                // INSTALL_FAILED_UPDATE_INCOMPATIBLE — the installed app and the
                // downloaded APK are signed with different keys.
                m.contains("UPDATE_INCOMPATIBLE") ||
                    m.contains("SIGNATURE") -> RESULT_BLOCKED_SIGNATURE
                else -> RESULT_BLOCKED_CONFLICT
            }
        }
    }

    fun isDeviceOwner(): Boolean = try {
        val dpm =
            context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        dpm.isDeviceOwnerApp(context.packageName)
    } catch (t: Throwable) {
        false
    }

    /**
     * Streams [path] into an install session and commits it.
     *
     * [onOutcome] fires once with a result key and an optional detail message.
     * On a *successful* self-update it will usually never fire at all — the
     * process is replaced before the broadcast is delivered. That is expected:
     * success is confirmed on the next launch by comparing the running version
     * against the recorded attempt. This callback exists for the failures.
     */
    fun install(path: String?, onOutcome: (String, String?) -> Unit): Boolean {
        if (path.isNullOrBlank()) return false
        val file = File(path)
        if (!file.exists()) {
            android.util.Log.w(TAG, "apk missing at $path")
            return false
        }

        return try {
            val installer = context.packageManager.packageInstaller
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isDeviceOwner()) {
                // Marks the install as policy-driven, which is what lets a
                // device-owner session through with no user interaction.
                params.setInstallReason(PackageManagerCompat.INSTALL_REASON_POLICY)
            }

            val sessionId = installer.createSession(params)
            installer.openSession(sessionId).use { session ->
                session.openWrite("apk", 0, file.length()).use { out ->
                    file.inputStream().use { input -> input.copyTo(out) }
                    session.fsync(out)
                }

                registerStatusReceiver(sessionId, onOutcome)
                session.commit(statusIntentSender(sessionId))
            }
            true
        } catch (t: Throwable) {
            // Deliberately NOT reporting an outcome here. Returning false makes
            // the caller fall back to the ACTION_VIEW installer, so announcing a
            // failure now would put "Update did not install" on screen while the
            // system installer is opening on top of it.
            android.util.Log.e(TAG, "session install failed — caller will fall back", t)
            false
        }
    }

    private fun statusIntentSender(sessionId: Int): android.content.IntentSender {
        val intent = Intent(ACTION_INSTALL_STATUS).setPackage(context.packageName)
        // FLAG_MUTABLE is required from S onward: the system fills the status
        // extras in on our behalf.
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, sessionId, intent, flags).intentSender
    }

    private fun registerStatusReceiver(
        sessionId: Int,
        onOutcome: (String, String?) -> Unit,
    ) {
        val receiver = object : BroadcastReceiver() {
            private var reported = false

            override fun onReceive(ctx: Context, intent: Intent) {
                val status = intent.getIntExtra(
                    PackageInstaller.EXTRA_STATUS,
                    PackageInstaller.STATUS_FAILURE,
                )
                val message =
                    intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)

                if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
                    // Not device owner — fall back to the prompt rather than
                    // failing. The final status arrives on a later broadcast, so
                    // this receiver stays registered.
                    val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                    }
                    confirm?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    runCatching { confirm?.let { ctx.startActivity(it) } }
                    onOutcome(RESULT_PENDING_USER_ACTION, null)
                    return
                }

                if (reported) return
                reported = true
                runCatching { ctx.unregisterReceiver(this) }

                val key = when (status) {
                    PackageInstaller.STATUS_SUCCESS -> RESULT_SUCCESS
                    PackageInstaller.STATUS_FAILURE_CONFLICT ->
                        classifyConflict(message)
                    PackageInstaller.STATUS_FAILURE_ABORTED -> RESULT_ABORTED
                    else -> RESULT_FAILURE
                }
                android.util.Log.i(TAG, "session $sessionId -> $key ($status) $message")
                onOutcome(key, message)
            }
        }

        ContextCompat.registerReceiver(
            context,
            receiver,
            IntentFilter(ACTION_INSTALL_STATUS),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }
}

/** Constants that are not exposed on every supported API level. */
private object PackageManagerCompat {
    /** `PackageManager.INSTALL_REASON_POLICY` — API 24+, value is stable. */
    const val INSTALL_REASON_POLICY = 1
}
