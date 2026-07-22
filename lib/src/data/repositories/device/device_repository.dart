import 'package:fndtv/src/data/data_sources/device/device_data_source.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';

/// Local-storage key holding the backend device id (UUID) captured at
/// registration. Needed to check for app updates.
const String kStbDeviceIdKey = 'stb_device_id';

/// Local-storage key holding the per-device Bearer token minted by the backend
/// at self-provisioning (`POST /api/provision`). Authorises `/device/checkin`.
/// Absent until the box has provisioned — check-in is skipped until it's here.
const String kStbDeviceTokenKey = 'stb_device_token';

abstract class DeviceRepository {
  Future<({ProvisionStatus status, String? deviceToken, String? deviceId})>
      provisionDevice({
    required String serialNumber,
    String? macWifi,
    String? androidId,
    String? model,
    String? osVersion,
  });

  Future<DeviceUpdateModel?> checkUpdate(String deviceId);

  Future<({DeviceCheckinStatus status, DeviceCheckinModel? model})> checkin({
    required String deviceToken,
    String? androidId,
    String? macAddress,
    String? installedAppVersion,
    String? deviceModel,
    String? osVersion,
  });

  Future<bool> ackCommand({
    required String commandId,
    required bool success,
    String? result,
  });
}

final class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required DeviceDataSource dataSource})
      : _dataSource = dataSource;

  final DeviceDataSource _dataSource;

  @override
  Future<({ProvisionStatus status, String? deviceToken, String? deviceId})>
      provisionDevice({
    required String serialNumber,
    String? macWifi,
    String? androidId,
    String? model,
    String? osVersion,
  }) {
    return _dataSource.provisionDevice(
      serialNumber: serialNumber,
      macWifi: macWifi,
      androidId: androidId,
      model: model,
      osVersion: osVersion,
    );
  }

  @override
  Future<DeviceUpdateModel?> checkUpdate(String deviceId) {
    return _dataSource.checkUpdate(deviceId);
  }

  @override
  Future<({DeviceCheckinStatus status, DeviceCheckinModel? model})> checkin({
    required String deviceToken,
    String? androidId,
    String? macAddress,
    String? installedAppVersion,
    String? deviceModel,
    String? osVersion,
  }) {
    return _dataSource.checkin(
      deviceToken: deviceToken,
      androidId: androidId,
      macAddress: macAddress,
      installedAppVersion: installedAppVersion,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }

  @override
  Future<bool> ackCommand({
    required String commandId,
    required bool success,
    String? result,
  }) {
    return _dataSource.ackCommand(
      commandId: commandId,
      success: success,
      result: result,
    );
  }
}
