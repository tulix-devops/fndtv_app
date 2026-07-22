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

  /// Resolves the single, reused APK download location
  /// (`<external-files>/apk/update.apk`), creating the directory if needed.
  /// One fixed filename means each download overwrites the last — the store
  /// never accumulates more than one APK.
  Future<File> _apkFile() async {
    final baseDir = await getExternalStorageDirectory() ??
        await getApplicationSupportDirectory();
    final apkDir = Directory('${baseDir.path}/apk');
    if (!apkDir.existsSync()) apkDir.createSync(recursive: true);
    return File('${apkDir.path}/update.apk');
  }

  /// Deletes any leftover downloaded APK. Safe to call at app startup: after a
  /// successful update the box has relaunched into the new build, so the file
  /// is dead weight; after a failed/cancelled install it's stale. Never called
  /// mid-install (the system installer needs the file until it finishes), so
  /// startup is the safe moment to reclaim the space.
  Future<void> cleanupDownloadedApk() async {
    try {
      final file = await _apkFile();
      if (file.existsSync()) {
        await file.delete();
        logger.i('[STB] Removed leftover update APK: ${file.path}');
      }
    } catch (e) {
      logger.w('[STB] Update APK cleanup error: $e');
    }
  }

  /// Downloads [url] to a FileProvider-accessible location, reporting progress
  /// in the range 0..1. Returns the saved file path.
  ///
  /// `GET /api/app-version/{id}/apk` is scoped to the per-device Bearer token,
  /// so [deviceToken] must be the provisioning-minted device token — without it
  /// the download is rejected with 401.
  Future<String> download(
    String url, {
    required void Function(double progress) onProgress,
    String? deviceToken,
  }) async {
    final path = (await _apkFile()).path;

    logger.i('[STB] Downloading update: $url -> $path');
    await _dio.download(
      url,
      path,
      options: (deviceToken != null && deviceToken.isNotEmpty)
          ? Options(headers: {'Authorization': 'Bearer $deviceToken'})
          : null,
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
