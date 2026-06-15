import 'package:local_storage/local_storage.dart';

final class LocalLocalizationDataSource {
  LocalLocalizationDataSource(this._localStorage);

  final LocalStorage _localStorage;
  final String _cacheKey = CacheKeys.locale;
  Future<String?> getLocale() {
    return _localStorage.get<String>(_cacheKey);
  }

  Future<void> setLocale(String value) {
    return _localStorage.store<String>(_cacheKey, value);
  }
}
