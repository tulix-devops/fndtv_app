import 'package:fndtv/src/data/data_sources/device/device_data_source.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';

/// Local-storage key holding the backend device id (UUID) captured at
/// registration. Needed to check for app updates.
const String kStbDeviceIdKey = 'stb_device_id';

abstract class DeviceRepository {
  Future<({DeviceRegisterResult status, String? deviceId})> registerSetTopBox({
    required String serialNumber,
    required String macWifi,
    required String osVersion,
  });

  Future<DeviceUpdateModel?> checkUpdate(String deviceId);
}

final class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({required DeviceDataSource dataSource})
      : _dataSource = dataSource;

  final DeviceDataSource _dataSource;

  @override
  Future<({DeviceRegisterResult status, String? deviceId})> registerSetTopBox({
    required String serialNumber,
    required String macWifi,
    required String osVersion,
  }) {
    return _dataSource.registerSetTopBox(
      serialNumber: serialNumber,
      macWifi: macWifi,
      osVersion: osVersion,
    );
  }

  @override
  Future<DeviceUpdateModel?> checkUpdate(String deviceId) {
    return _dataSource.checkUpdate(deviceId);
  }
}
