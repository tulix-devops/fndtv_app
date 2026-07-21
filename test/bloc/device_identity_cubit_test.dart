import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/device_identity_cubit/device_identity_cubit.dart';

void main() {
  test('load() fills identity from injected readers', () async {
    final cubit = DeviceIdentityCubit(
      readMac: () async => 'A4:3E:31:7B:22:10',
      readSerial: () async => 'X88P14-004512',
      readDeviceId: () async => 'd41f-9c2a',
      readVersion: () async => '1.3.2',
    );
    await cubit.load();
    expect(cubit.state.mac, 'A4:3E:31:7B:22:10');
    expect(cubit.state.serial, 'X88P14-004512');
    expect(cubit.state.deviceId, 'd41f-9c2a');
    expect(cubit.state.version, '1.3.2');
    expect(cubit.state.loaded, isTrue);
    await cubit.close();
  });

  test('reader errors leave empty values, still marks loaded', () async {
    final cubit = DeviceIdentityCubit(
      readMac: () async => throw Exception('boom'),
      readSerial: () async => '',
      readDeviceId: () async => null,
      readVersion: () async => '',
    );
    await cubit.load();
    expect(cubit.state.mac, '');
    expect(cubit.state.deviceId, isNull);
    expect(cubit.state.loaded, isTrue);
    await cubit.close();
  });
}
