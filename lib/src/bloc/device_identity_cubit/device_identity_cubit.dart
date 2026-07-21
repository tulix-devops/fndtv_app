import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceIdentityState extends Equatable {
  final String mac;
  final String serial;
  final String? deviceId;
  final String version;
  final bool loaded;

  const DeviceIdentityState({
    this.mac = '',
    this.serial = '',
    this.deviceId,
    this.version = '',
    this.loaded = false,
  });

  @override
  List<Object?> get props => [mac, serial, deviceId, version, loaded];
}

/// Loads the box identity once for the badge / Network page / offline overlay.
/// Reader functions are injected so the cubit is trivially testable; production
/// wiring lives in AppBlocProvider.
class DeviceIdentityCubit extends Cubit<DeviceIdentityState> {
  DeviceIdentityCubit({
    required Future<String> Function() readMac,
    required Future<String> Function() readSerial,
    required Future<String?> Function() readDeviceId,
    required Future<String> Function() readVersion,
  })  : _readMac = readMac,
        _readSerial = readSerial,
        _readDeviceId = readDeviceId,
        _readVersion = readVersion,
        super(const DeviceIdentityState());

  final Future<String> Function() _readMac;
  final Future<String> Function() _readSerial;
  final Future<String?> Function() _readDeviceId;
  final Future<String> Function() _readVersion;

  Future<void> load() async {
    Future<T> safe<T>(Future<T> Function() f, T fallback) async {
      try {
        return await f();
      } catch (_) {
        return fallback;
      }
    }

    emit(DeviceIdentityState(
      mac: await safe(_readMac, ''),
      serial: await safe(_readSerial, ''),
      deviceId: await safe(_readDeviceId, null),
      version: await safe(_readVersion, ''),
      loaded: true,
    ));
  }
}
