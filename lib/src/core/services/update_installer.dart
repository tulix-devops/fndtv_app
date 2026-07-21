import 'dart:io';

import 'package:app_logger/app_logger.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads an update APK, verifies it, and hands it to the system installer.
class UpdateInstaller {
  static const MethodChannel _channel =
      MethodChannel('com.fndtv.videoplayer/device');

  final Dio _dio = Dio();

  /// Downloads [url] to a FileProvider-accessible location, reporting progress
  /// in the range 0..1. Returns the saved file path.
  Future<String> download(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final baseDir =
        await getExternalStorageDirectory() ?? await getApplicationSupportDirectory();
    final apkDir = Directory('${baseDir.path}/apk');
    if (!apkDir.existsSync()) apkDir.createSync(recursive: true);
    final path = '${apkDir.path}/update.apk';

    logger.i('[STB] Downloading update: $url -> $path');
    await _dio.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    return path;
  }

  /// Verifies the file's SHA-256 against [expected]. Returns true on match, or
  /// when [expected] is a placeholder (empty / all-zeros) — in which case the
  /// check is skipped with a warning.
  Future<bool> verify(String path, String? expected) async {
    if (expected == null ||
        expected.isEmpty ||
        RegExp(r'^0+$').hasMatch(expected)) {
      logger.w('[STB] Skipping SHA-256 verify (placeholder/empty hash).');
      return true;
    }
    final bytes = await File(path).readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final ok = digest.toLowerCase() == expected.toLowerCase();
    if (!ok) {
      logger.w('[STB] SHA-256 mismatch: got $digest, expected $expected');
    }
    return ok;
  }

  /// Launches the system package installer for the downloaded APK.
  Future<bool> install(String path) async {
    try {
      final res = await _channel.invokeMethod<bool>('installApk', {'path': path});
      return res ?? false;
    } catch (e) {
      logger.w('[STB] install error: $e');
      return false;
    }
  }
}
