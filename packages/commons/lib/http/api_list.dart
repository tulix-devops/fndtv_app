const String _url = 'https://fnd.dineo.uk/api';

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

  // Auth endpoints
  static String get login => '$_url/auth/login';
  static String get signUp => '$_url/auth/signup';
  static String get logout => '$_url/auth/logout';
  static String get forgotPassword => '$_url/auth/forgot-password';
  static String get loginWithBiometrics => '$_url/auth/login-with-biometrics';
}
