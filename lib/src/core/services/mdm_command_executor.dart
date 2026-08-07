import 'package:app_logger/app_logger.dart';
import 'package:fndtv/src/core/services/kiosk_lock_controller.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:fndtv/src/core/services/update_installer.dart';
import 'package:fndtv/src/core/services/update_progress_controller.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart';
import 'package:local_storage/local_storage.dart';

/// The MDM command types this box can execute. Anything else (`PUSH_CONFIG`,
/// `GET_LOGS`, `WIPE`) is logged and left pending — out of scope for now.
const Set<String> kSupportedMdmCommands = {
  'REBOOT',
  'KIOSK_LOCK',
  'KIOSK_UNLOCK',
  'UPDATE_APP',
};

/// Executes MDM commands delivered in a check-in response and acknowledges them
/// (`POST /api/command/{id}/ack`).
///
/// **Ack ordering matters.** Commands that make the app vanish mid-execution
/// (REBOOT, and the install step of UPDATE_APP) are acked *before* the
/// disappearing action — otherwise the backend, seeing no ack, redelivers the
/// command on every check-in and the box loops forever. Everything else acks
/// *after* so a genuine failure can report `FAILED`.
///
/// Idempotent within a session: each command id is executed at most once, so a
/// fast poll that redelivers a not-yet-acked command doesn't double-run it.
class MdmCommandExecutor {
  MdmCommandExecutor({
    required DeviceRepository deviceRepository,
    required StbSystemService systemService,
    required KioskLockController kioskLockController,
    required LocalStorage localStorage,
    UpdateInstaller? updateInstaller,
    UpdateProgressController? updateProgressController,
  })  : _repo = deviceRepository,
        _system = systemService,
        _kiosk = kioskLockController,
        _storage = localStorage,
        _installer = updateInstaller ?? UpdateInstaller(),
        _updateProgress = updateProgressController;

  final DeviceRepository _repo;
  final StbSystemService _system;
  final KioskLockController _kiosk;
  final LocalStorage _storage;
  final UpdateInstaller _installer;

  /// Drives the on-screen "Updating…" overlay during UPDATE_APP. Null off-STB.
  final UpdateProgressController? _updateProgress;

  /// Command ids already handled this session — prevents a redelivered command
  /// (ack still in flight) from executing twice.
  final Set<String> _handled = <String>{};

  /// Executes every command in [commands] sequentially.
  Future<void> executeAll(List<DeviceCommandModel> commands) async {
    for (final command in commands) {
      await execute(command);
    }
  }

  /// Executes a single [command] and acknowledges it. Never throws.
  Future<void> execute(DeviceCommandModel command) async {
    final id = command.id;
    final type = command.type.toUpperCase();

    if (id.isEmpty) {
      logger.w('[STB] MDM command has no id; skipping: $type');
      return;
    }
    if (_handled.contains(id)) return; // already processed this session
    _handled.add(id);

    logger.i('[STB] MDM executing $type (id=$id)');
    try {
      switch (type) {
        case 'REBOOT':
          // Vanishing action → ack first, then reboot.
          await _ack(id, true);
          await _system.reboot();
        case 'KIOSK_LOCK':
          await _kiosk.setLocked(true);
          await _ack(id, true);
        case 'KIOSK_UNLOCK':
          await _kiosk.setLocked(false);
          await _ack(id, true);
        case 'UPDATE_APP':
          await _handleUpdate(id);
        default:
          logger.w('[STB] MDM command $type not supported; leaving pending.');
      }
    } catch (e) {
      logger.w('[STB] MDM command $type failed: $e');
      await _ack(id, false, result: e.toString());
    }
  }

  /// UPDATE_APP: reuse the existing update flow. Re-checks the update endpoint
  /// (so an already-current box is a no-op), downloads + verifies the APK, acks
  /// success *before* handing off to the installer (the install can relaunch
  /// the app), then installs.
  Future<void> _handleUpdate(String id) async {
    final deviceId = await _storage.get<String>(kStbDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      await _ack(id, false, result: 'no device id');
      return;
    }

    final token = await _storage.get<String>(kStbDeviceTokenKey);
    final model = await _repo.checkUpdate(deviceId, deviceToken: token);
    if (model == null) {
      await _ack(id, false, result: 'update check failed');
      return;
    }
    if (!model.updateRequired) {
      logger.i('[STB] UPDATE_APP: already up to date (v${model.latestVersion}).');
      await _ack(id, true, result: 'already up to date');
      return;
    }

    final url = model.apkDownloadUrl;
    if (url == null || url.isEmpty) {
      await _ack(id, false, result: 'no apk url');
      return;
    }

    // Show the "Updating…" overlay so the user isn't watching a frozen-looking
    // screen while the APK downloads in the background. Always hidden on exit.
    try {
      _updateProgress?.showDownloading(0);
      final path = await _installer.download(
        url,
        deviceToken: token,
        onProgress: (p) => _updateProgress?.showDownloading(p),
      );
      final ok = await _installer.verify(path, model.apkSha256);
      if (!ok) {
        await _ack(id, false, result: 'apk verification failed');
        return;
      }

      // Verified and about to install — the installer may relaunch the app, so
      // ack now (before the vanishing action) to avoid a redelivery loop.
      _updateProgress?.showInstalling();
      await _ack(id, true, result: 'installing v${model.latestVersion}');

      final outcome = await _installer.install(path);
      // Reaching here at all usually means the install did not take — a
      // successful one replaces this process first. The command was already
      // acked above and is deliberately not re-acked (the backend has no
      // defined semantics for a second ack), but the reason must not vanish:
      // this is the line that distinguishes "refused as a downgrade" from
      // "someone dismissed the prompt".
      if (outcome.didNotInstall) {
        logger.w('[STB] UPDATE_APP install did not land: ${outcome.kind}'
            '${outcome.message == null ? '' : ' — ${outcome.message}'}');
      }
    } finally {
      _updateProgress?.hide();
    }
  }

  Future<void> _ack(String id, bool success, {String? result}) async {
    final token = await _storage.get<String>(kStbDeviceTokenKey);
    if (token == null || token.isEmpty) {
      logger.w('[STB] No device token; cannot ack command $id.');
      return;
    }
    final accepted = await _repo.ackCommand(
      commandId: id,
      deviceToken: token,
      success: success,
      result: result,
    );
    if (!accepted) {
      logger.w('[STB] MDM ack not accepted for $id (success=$success).');
    }
  }
}
