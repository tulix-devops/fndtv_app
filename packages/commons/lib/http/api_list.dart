// const String _url = 'https://208.79.153.183/api';
// const String _url = 'https://watctv57.tulix.net/api';
// const String _url = 'http://192.168.1.154:8000/api';

const String _url = 'https://jbs.dineo.uk/api';

class APIList {
  APIList._();

  static String getContentTypeList() => '$_url/content-type/list';

  static String getContent({required int contentType, int? page}) {
    final baseUrl = '$_url/content/$contentType/list';
    return page != null ? '$baseUrl?page=$page' : baseUrl;
  }

  // Auth endpoints
  static String get login => '$_url/auth/login';
  static String get signUp => '$_url/auth/signup';
  static String get logout => '$_url/auth/logout';
  static String get forgotPassword => '$_url/auth/forgot-password';
  static String get loginWithBiometrics => '$_url/auth/login-with-biometrics';
}
