package com.fndtv.videoplayer

import android.app.Activity
import android.os.Bundle

/// Self-update (OTA) entry point. The full flow — check the update endpoint for
/// a newer version, download the APK, then launch the package installer via the
/// `${applicationId}.provider` FileProvider — is TODO and needs the update
/// endpoint + versioning contract to be defined first.
class UpgradeActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TODO: implement OTA update (version check, APK download, installer intent).
        finish()
    }
}
