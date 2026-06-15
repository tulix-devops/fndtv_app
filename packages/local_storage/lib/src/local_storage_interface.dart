part of 'local_storage_impl.dart';

abstract interface class LocalStorage {
  Future<void> init();
  Future<T?> get<T>(String key);
  Future<void> store<T>(String key, T value);
  Future<void> delete(String key);
  Future<bool> has<T>(String key);
}
