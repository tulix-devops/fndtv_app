import 'package:local_storage/local_storage.dart';

const String _cacheKey = CacheKeys.auth;

final class LocalAuthDataSource {
  LocalAuthDataSource(this._localStorage);

  final LocalStorage _localStorage;

  Future<String?> getToken() => _localStorage.get<String>(_cacheKey);

  Future<void> storeToken(String value) =>
      _localStorage.store<String>(_cacheKey, value);

  Future<void> deleteToken() => _localStorage.delete(_cacheKey);
}
