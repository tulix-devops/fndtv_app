package com.fndtv.videoplayer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// Boot receiver for the set-top box.
///
/// It must NOT call `startActivity(MainActivity)`: launching an activity from a
/// background broadcast receiver is blocked by Android's Background Activity
/// Launch restriction (BAL_BLOCK). A real launcher doesn't force itself to the
/// screen on boot anyway — once FNDTV is the default HOME app (device-owner +
/// set-home-activity, with the stock launcher disabled), the system starts it
/// automatically via the HOME intent. Left as a hook for background init only.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.i("BootReceiver", "boot completed; HOME intent starts FNDTV (no BAL launch)")
                // Intentionally no startActivity() — see class doc.
            }
        }
    }
}
