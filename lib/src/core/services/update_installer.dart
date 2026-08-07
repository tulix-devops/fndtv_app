import 'dart:async';
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

  /// Whether this box can install silently (device owner). Callers use it only
  /// to set expectations in the UI — the install path decides for itself.
  Future<bool> isDeviceOwner() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;
    } catch (e) {
      logger.w('[STB] isDeviceOwner error: $e');
      return false;
    }
  }

  /// Installs the downloaded APK and reports what happened.
  ///
  /// Resolves as soon as the outcome is known. On a *successful* self-update it
  /// normally never resolves at all: the process is replaced before the status
  /// broadcast is delivered. That is expected and handled — the Updates page
  /// confirms success on next launch by comparing the running version against
  /// the attempt it recorded, so this future is only load-bearing for failures.
  Future<StbInstallOutcome> install(String path) async {
    final completer = Completer<StbInstallOutcome>();

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onInstallOutcome') return null;
      final args = (call.arguments as Map?) ?? const {};
      final outcome = StbInstallOutcome.parse(
        args['outcome'] as String?,
        args['message'] as String?,
      );
      logger.i('[STB] install outcome: ${outcome.kind}'
          '${outcome.message == null ? '' : ' — ${outcome.message}'}');
      // PENDING_USER_ACTION is not terminal: the prompt is up and a real status
      // follows once the viewer answers it.
      if (outcome.kind == StbInstallResult.pendingUserAction) return null;
      if (!completer.isCompleted) completer.complete(outcome);
      return null;
    });

    try {
      final started =
          await _channel.invokeMethod<bool>('installApk', {'path': path});
      if (started != true) {
        return const StbInstallOutcome(StbInstallResult.failure, 'not started');
      }
    } catch (e) {
      logger.w('[STB] install error: $e');
      return StbInstallOutcome(StbInstallResult.failure, '$e');
    }

    // A silent device-owner install replaces this process, so waiting forever
    // would strand the UI on a spinner in the one case that actually worked.
    final outcome = await completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () =>
          const StbInstallOutcome(StbInstallResult.unknown, 'timed out'),
    );
    // Released so a later install (manual page vs MDM push) does not deliver
    // its result into this finished completer.
    _channel.setMethodCallHandler(null);
    return outcome;
  }
}

/// Why an install ended. Mirrors the keys in `ApkInstaller.kt`.
enum StbInstallResult {
  success,

  /// Android refused the APK because its versionCode is not higher than what is
  /// installed. This is the failure that used to be invisible — the update
  /// "installed" and the box stayed on the old build.
  blockedDowngrade,

  /// The installed app and the downloaded APK are signed with different keys
  /// (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Needs a different fix from a
  /// downgrade — the APK on the server was built with the wrong keystore — so
  /// it must not be reported as one.
  blockedSignature,

  /// Conflicts with the installed package for some other reason.
  blockedConflict,

  /// Cancelled, by the viewer or by the system.
  aborted,

  /// The session is waiting on the user to confirm (box is not device owner).
  pendingUserAction,
  failure,

  /// No status arrived. Usually means the install succeeded and took the
  /// process with it.
  unknown,
}

class StbInstallOutcome {
  final StbInstallResult kind;
  final String? message;

  const StbInstallOutcome(this.kind, [this.message]);

  bool get didNotInstall =>
      kind == StbInstallResult.blockedDowngrade ||
      kind == StbInstallResult.blockedSignature ||
      kind == StbInstallResult.blockedConflict ||
      kind == StbInstallResult.aborted ||
      kind == StbInstallResult.failure;

  static StbInstallOutcome parse(String? key, String? message) {
    final kind = switch (key) {
      'success' => StbInstallResult.success,
      'blocked_downgrade' => StbInstallResult.blockedDowngrade,
      'blocked_signature' => StbInstallResult.blockedSignature,
      'blocked_conflict' => StbInstallResult.blockedConflict,
      'aborted' => StbInstallResult.aborted,
      'pending_user_action' => StbInstallResult.pendingUserAction,
      'failure' => StbInstallResult.failure,
      _ => StbInstallResult.unknown,
    };
    return StbInstallOutcome(kind, message);
  }
}
