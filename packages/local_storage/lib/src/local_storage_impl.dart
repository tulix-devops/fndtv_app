import 'package:hive_flutter/hive_flutter.dart';

part 'local_storage_interface.dart';

abstract final class CacheKeys {
  static const String isOnboardingComplete = 'isOnboardingComplete';
  static const String auth = 'auth';
  static const String locale = 'locale';
  static const String device = 'device';
  static const String hasEnabledBiometrics = 'hasEnabledBiometrics';
  static const String savedList = 'savedList';
  static const String isDarkMode = 'isDarkMode';
  static const String themeColor = 'themeColor';
  static const String contentList = 'contentList';
  static const String cacheTimestamp = 'contentCacheTimestamp';
}

final class HiveLocalStorage implements LocalStorage {
  late final Box<dynamic> _appBox;

  @override
  Future<void> init() async {
    await Hive.initFlutter();

    _appBox = await Hive.openBox('app');
  }

  @override
  Future<T?> get<T>(String key) async {
    if (!_appBox.containsKey(key)) return null;

    return _appBox.get(key, defaultValue: null) as T;
  }

  @override
  Future<void> delete(String key) {
    return _appBox.delete(key);
  }

  @override
  Future<void> store<T>(String key, T value) {
    return _appBox.put(key, value);
  }

  @override
  Future<bool> has<T>(String key) {
    return Future.value(_appBox.containsKey(key));
  }
}
