const String _url = 'https://fnd.dineo.uk/api';

/// Separate backend host for set-top box provisioning (device registration).
const String _boxUrl = 'https://box.dineo.uk/api';

class APIList {
  APIList._();

  static String getContentTypeList() => '$_url/content-type/list';

  static String getContent({required int contentType, int? page}) {
    final baseUrl = '$_url/content/$contentType/list';
    return page != null ? '$baseUrl?page=$page' : baseUrl;
  }

  /// Single content item (channel) detail, including its `seasons` schedule
  /// (the EPG / DVR program list). Optional [date] (YYYY-MM-DD) selects the
  /// archive day (backend support pending — currently returns a rolling window).
  static String getContentDetail({
    required int contentType,
    required int id,
    String? date,
  }) {
    final base = '$_url/content/$contentType/$id';
    return date != null ? '$base?date=$date' : base;
  }

  /// Operator login on the box host. POST `{ email, password }` → 200 with a
  /// `tulix_session` cookie (HttpOnly) that authorises device registration.
  ///
  /// INTERIM: per the Box API design, `/device/register` is a warehouse-side
  /// operator action, not something the box does — devices are meant to hold a
  /// per-device Bearer token minted at provisioning. Self-registration (and
  /// this login) stays only until the provisioning/token flow exists.
  static String get operatorLogin => '$_boxUrl/auth/login';

  /// Registers this set-top box on app init. POST body:
  /// `{ serial_number, mac_wifi, os_version }` with the operator session cookie.
  /// Returns 201 on success, 409 if the box is already registered.
  /// See [operatorLogin] — interim until boxes are provisioned with tokens.
  static String get registerDevice => '$_boxUrl/device/register';

  /// Checks whether the box needs a newer app build. GET by device id (the UUID
  /// from registration), PUBLIC (no auth) → returns the latest version, an
  /// `update_required` flag, and (if so) the APK URL + SHA-256.
  static String deviceUpdate(String deviceId) =>
      '$_boxUrl/device/$deviceId/update';

  /// Runtime config for the box (tenant, app version, channel-list URL, DPS/MDM
  /// endpoints). GET by device id, PUBLIC (no auth).
  static String deviceConfig(String deviceId) =>
      '$_boxUrl/device/$deviceId/config';

  /// Device check-in — the box's runtime heartbeat. POST device state
  /// (`android_id`, `mac_address`, `installed_app_version`, `device_model`,
  /// `os_version`) with `Authorization: Bearer <device token>` → latest app
  /// version + APK URL, DRM token, channel-list URL, and pending MDM commands.
  /// 401 bad token, 409 DEVICE_UNASSIGNED, 403 subscriber suspended/cancelled.
  static String get deviceCheckin => '$_boxUrl/device/checkin';

  /// Acknowledge an executed MDM command. POST `{ status: ACKED|FAILED,
  /// result? }` by command id (received in the check-in response).
  static String commandAck(String commandId) =>
      '$_boxUrl/command/$commandId/ack';

  /// Cheap reachability probe target on the box host (`GET /api/health`).
  static String get boxHealth => '$_boxUrl/health';

  // Auth endpoints
  static String get login => '$_url/auth/login';
  static String get signUp => '$_url/auth/signup';
  static String get logout => '$_url/auth/logout';
  static String get forgotPassword => '$_url/auth/forgot-password';
  static String get loginWithBiometrics => '$_url/auth/login-with-biometrics';
}
