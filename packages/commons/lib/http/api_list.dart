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
  static String get operatorLogin => '$_boxUrl/auth/login';

  /// Registers this set-top box on app init. POST body:
  /// `{ serial_number, mac_wifi, os_version }` with the operator session cookie.
  /// Returns 201 on success, 409 if the box is already registered.
  static String get registerDevice => '$_boxUrl/device/register';

  /// Checks whether the box needs a newer app build. GET by device id (the UUID
  /// from registration) with the operator session cookie → returns the latest
  /// version, an `update_required` flag, and (if so) the APK URL + SHA-256.
  static String deviceUpdate(String deviceId) =>
      '$_boxUrl/device/$deviceId/update';

  // Auth endpoints
  static String get login => '$_url/auth/login';
  static String get signUp => '$_url/auth/signup';
  static String get logout => '$_url/auth/logout';
  static String get forgotPassword => '$_url/auth/forgot-password';
  static String get loginWithBiometrics => '$_url/auth/login-with-biometrics';
}
