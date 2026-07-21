package com.fndtv.videoplayer

import android.app.admin.DeviceAdminReceiver

/// Device admin receiver. Being a registered device admin lets the box enforce
/// kiosk / lockdown policies (declared in res/xml/device_admin_rules.xml).
class MyDeviceAdminReceiver : DeviceAdminReceiver()
