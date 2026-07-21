package com.fndtv.videoplayer

import android.app.Service
import android.content.Intent
import android.os.IBinder

/// Foreground startup service for boot-time work on the box (e.g. a health
/// ping or watchdog). Declared for parity with the reference kiosk manifest;
/// nothing starts it yet — add boot-time logic here as needed.
class StartupService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // TODO: boot-time startup work (health ping / watchdog).
        return START_NOT_STICKY
    }
}
