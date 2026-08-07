import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/core/services/kiosk_lock_controller.dart';
import 'package:fndtv/src/core/services/mdm_command_executor.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:fndtv/src/core/services/update_installer.dart';
import 'package:fndtv/src/data/data_sources/device/device_data_source.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart';
import 'package:local_storage/local_storage.dart';

/// Records the sequence of side effects so tests can assert ordering.
class _Trace {
  final List<String> events = [];
}

class _FakeStorage implements LocalStorage {
  _FakeStorage({String deviceToken = 'device-token'}) {
    _m[kStbDeviceTokenKey] = deviceToken;
  }
  final Map<String, Object?> _m = {};
  @override
  Future<void> init() async {}
  @override
  Future<T?> get<T>(String key) async => _m[key] as T?;
  @override
  Future<void> store<T>(String key, T value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
  @override
  Future<bool> has<T>(String key) async => _m.containsKey(key);
}

class _FakeRepo implements DeviceRepository {
  _FakeRepo(this.trace, {this.updateModel});
  final _Trace trace;
  DeviceUpdateModel? updateModel;
  final List<({String id, bool success, String? result})> acks = [];

  @override
  Future<bool> ackCommand({
    required String commandId,
    required String deviceToken,
    required bool success,
    String? result,
  }) async {
    trace.events.add('ack:$commandId:${success ? 'ACKED' : 'FAILED'}');
    acks.add((id: commandId, success: success, result: result));
    return true;
  }

  @override
  Future<DeviceUpdateModel?> checkUpdate(String deviceId,
      {String? deviceToken}) async {
    trace.events.add('checkUpdate');
    return updateModel;
  }

  @override
  Future<({DeviceCheckinStatus status, DeviceCheckinModel? model})> checkin({
    required String deviceToken,
    String? androidId,
    String? macAddress,
    String? installedAppVersion,
    String? installedVersionCode,
    String? deviceModel,
    String? osVersion,
  }) async =>
      (status: DeviceCheckinStatus.failed, model: null);

  @override
  Future<({ProvisionStatus status, String? deviceToken, String? deviceId})>
      provisionDevice({
    required String serialNumber,
    String? macWifi,
    String? androidId,
    String? model,
    String? osVersion,
  }) async =>
          (status: ProvisionStatus.failed, deviceToken: null, deviceId: null);
}

class _FakeSystem extends StbSystemService {
  _FakeSystem(this.trace);
  final _Trace trace;
  @override
  Future<bool> reboot() async {
    trace.events.add('reboot');
    return true;
  }
}

class _FakeInstaller extends UpdateInstaller {
  _FakeInstaller(this.trace, {this.verifyResult = true});
  final _Trace trace;
  final bool verifyResult;

  @override
  Future<String> download(String url,
      {required void Function(double) onProgress, String? deviceToken}) async {
    trace.events.add('download');
    return '/tmp/update.apk';
  }

  @override
  Future<bool> verify(String path, String? expected) async {
    trace.events.add('verify');
    return verifyResult;
  }

  /// What the installer reports back. Defaults to the case a real box almost
  /// never reaches — a successful self-install replaces the process first.
  StbInstallOutcome installOutcome =
      const StbInstallOutcome(StbInstallResult.success);

  @override
  Future<StbInstallOutcome> install(String path) async {
    trace.events.add('install');
    return installOutcome;
  }
}

DeviceCommandModel _cmd(String type, {String id = 'c1'}) =>
    DeviceCommandModel(id: id, type: type, payload: null, raw: const {});

MdmCommandExecutor _executor(
  _Trace trace, {
  _FakeRepo? repo,
  KioskLockController? kiosk,
  _FakeInstaller? installer,
  _FakeStorage? storage,
}) {
  final s = storage ?? _FakeStorage();
  return MdmCommandExecutor(
    deviceRepository: repo ?? _FakeRepo(trace),
    systemService: _FakeSystem(trace),
    kioskLockController: kiosk ?? KioskLockController(localStorage: s),
    localStorage: s,
    updateInstaller: installer ?? _FakeInstaller(trace),
  );
}

void main() {
  group('REBOOT', () {
    test('acks BEFORE rebooting (vanishing action)', () async {
      final trace = _Trace();
      await _executor(trace).execute(_cmd('REBOOT'));
      expect(trace.events, ['ack:c1:ACKED', 'reboot']);
    });
  });

  group('KIOSK_LOCK / KIOSK_UNLOCK', () {
    test('KIOSK_LOCK locks the controller then acks', () async {
      final trace = _Trace();
      final kiosk = KioskLockController(localStorage: _FakeStorage());
      await _executor(trace, kiosk: kiosk).execute(_cmd('KIOSK_LOCK'));
      expect(kiosk.isLocked, isTrue);
      expect(trace.events, ['ack:c1:ACKED']);
    });

    test('KIOSK_UNLOCK unlocks the controller', () async {
      final trace = _Trace();
      final kiosk = KioskLockController(localStorage: _FakeStorage());
      await kiosk.setLocked(true);
      await _executor(trace, kiosk: kiosk).execute(_cmd('KIOSK_UNLOCK'));
      expect(kiosk.isLocked, isFalse);
    });
  });

  group('UPDATE_APP', () {
    test('no device id → acks FAILED, no download', () async {
      final trace = _Trace();
      final repo = _FakeRepo(trace);
      await _executor(trace, repo: repo).execute(_cmd('UPDATE_APP'));
      expect(repo.acks.single.success, isFalse);
      expect(trace.events, isNot(contains('download')));
    });

    test('already up to date → acks ACKED, no download', () async {
      final trace = _Trace();
      final storage = _FakeStorage();
      await storage.store<String>(kStbDeviceIdKey, 'dev-1');
      final repo = _FakeRepo(trace,
          updateModel: const DeviceUpdateModel(
            installedVersion: '1.0.0',
            latestVersion: '1.0.0',
            updateRequired: false,
          ));
      await _executor(trace, repo: repo, storage: storage)
          .execute(_cmd('UPDATE_APP'));
      expect(repo.acks.single.success, isTrue);
      expect(trace.events, ['checkUpdate', 'ack:c1:ACKED']);
    });

    test('update required → download, verify, ack BEFORE install', () async {
      final trace = _Trace();
      final storage = _FakeStorage();
      await storage.store<String>(kStbDeviceIdKey, 'dev-1');
      final repo = _FakeRepo(trace,
          updateModel: const DeviceUpdateModel(
            installedVersion: '1.0.0',
            latestVersion: '1.1.0',
            updateRequired: true,
            apkDownloadUrl: 'https://x/app.apk',
            apkSha256: 'abc',
          ));
      await _executor(trace, repo: repo, storage: storage)
          .execute(_cmd('UPDATE_APP'));
      expect(trace.events,
          ['checkUpdate', 'download', 'verify', 'ack:c1:ACKED', 'install']);
    });

    test('verify failure → acks FAILED, does NOT install', () async {
      final trace = _Trace();
      final storage = _FakeStorage();
      await storage.store<String>(kStbDeviceIdKey, 'dev-1');
      final repo = _FakeRepo(trace,
          updateModel: const DeviceUpdateModel(
            installedVersion: '1.0.0',
            latestVersion: '1.1.0',
            updateRequired: true,
            apkDownloadUrl: 'https://x/app.apk',
            apkSha256: 'abc',
          ));
      await _executor(trace,
              repo: repo,
              storage: storage,
              installer: _FakeInstaller(trace, verifyResult: false))
          .execute(_cmd('UPDATE_APP'));
      expect(repo.acks.single.success, isFalse);
      expect(trace.events, isNot(contains('install')));
    });
  });

  group('dedup + unsupported', () {
    test('same command id runs only once', () async {
      final trace = _Trace();
      final exec = _executor(trace);
      await exec.execute(_cmd('REBOOT', id: 'dup'));
      await exec.execute(_cmd('REBOOT', id: 'dup'));
      expect(trace.events.where((e) => e == 'reboot').length, 1);
    });

    test('unsupported command is left pending (no ack)', () async {
      final trace = _Trace();
      final repo = _FakeRepo(trace);
      await _executor(trace, repo: repo).execute(_cmd('WIPE'));
      expect(repo.acks, isEmpty);
    });

    test('command with empty id is ignored', () async {
      final trace = _Trace();
      final repo = _FakeRepo(trace);
      await _executor(trace, repo: repo).execute(_cmd('REBOOT', id: ''));
      expect(trace.events, isEmpty);
    });
  });
}
