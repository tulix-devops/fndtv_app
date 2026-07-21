import 'dart:convert';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';
import 'package:http/http.dart' as http;

/// Outcome of a set-top box registration attempt.
enum DeviceRegisterResult {
  /// HTTP 201 — the box was registered.
  registered,

  /// HTTP 409 — the box was already registered (treated as done).
  alreadyRegistered,

  /// Login failed, any other status, or a transport error — retry next launch.
  failed,
}

/// Talks to the box provisioning backend.
///
/// The `/device/register` endpoint is an operator action guarded by a session
/// cookie, so registration is a two-step call: log in as the operator to obtain
/// the `tulix_session` cookie, then POST the device payload with that cookie.
///
/// Uses its own [http.Client] (not the shared app client) so it neither leaks
/// the fnd user bearer token to the box host nor relies on the app's envelope
/// response handling — this REST endpoint signals via the HTTP status.
final class DeviceDataSource {
  DeviceDataSource();

  // Operator credentials used to obtain the session cookie. Embedded because
  // the box self-registers on boot with no interactive login.
  // TODO: move to a build-time/config secret if these ever need to rotate.
  static const String _operatorEmail = 'app@fndtv.com';
  static const String _operatorPassword = 'fdsf@3q!!3';

  final http.Client _client = http.Client();

  /// Registers the box. On success (201) the response carries the backend
  /// `device_id` (a UUID) — returned here so it can be persisted for later
  /// update checks. The 409 "already registered" response does NOT include it.
  Future<({DeviceRegisterResult status, String? deviceId})> registerSetTopBox({
    required String serialNumber,
    required String macWifi,
    required String osVersion,
  }) async {
    try {
      final cookie = await _operatorSession();
      if (cookie == null) return (status: DeviceRegisterResult.failed, deviceId: null);

      final response = await _client.post(
        Uri.parse(APIList.registerDevice),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': cookie,
        },
        body: jsonEncode(<String, dynamic>{
          'serial_number': serialNumber,
          'mac_wifi': macWifi,
          'os_version': osVersion,
        }),
      );

      switch (response.statusCode) {
        case 201:
          return (
            status: DeviceRegisterResult.registered,
            deviceId: _extractDeviceId(response.body),
          );
        case 409:
          return (status: DeviceRegisterResult.alreadyRegistered, deviceId: null);
        default:
          logger.w(
            '[STB] register HTTP ${response.statusCode}: ${response.body}',
          );
          return (status: DeviceRegisterResult.failed, deviceId: null);
      }
    } catch (e) {
      logger.w('[STB] register request error: $e');
      return (status: DeviceRegisterResult.failed, deviceId: null);
    }
  }

  /// Checks whether a newer app build is available for [deviceId], or null if
  /// the check couldn't be completed. The endpoint is public — no auth.
  Future<DeviceUpdateModel?> checkUpdate(String deviceId) async {
    try {
      final response = await _client.get(
        Uri.parse(APIList.deviceUpdate(deviceId)),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DeviceUpdateModel.fromJson(json);
      }

      logger.w(
        '[STB] update check HTTP ${response.statusCode}: ${response.body}',
      );
      return null;
    } catch (e) {
      logger.w('[STB] update check error: $e');
      return null;
    }
  }

  /// Reports the box's state to the backend (`POST /device/checkin`) using its
  /// per-device Bearer [deviceToken] minted at provisioning. All payload
  /// fields are optional server-side — send whatever identity is available.
  Future<({DeviceCheckinStatus status, DeviceCheckinModel? model})> checkin({
    required String deviceToken,
    String? androidId,
    String? macAddress,
    String? installedAppVersion,
    String? deviceModel,
    String? osVersion,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(APIList.deviceCheckin),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $deviceToken',
        },
        body: jsonEncode(<String, dynamic>{
          if (androidId != null && androidId.isNotEmpty)
            'android_id': androidId,
          if (macAddress != null && macAddress.isNotEmpty)
            'mac_address': macAddress,
          if (installedAppVersion != null && installedAppVersion.isNotEmpty)
            'installed_app_version': installedAppVersion,
          if (deviceModel != null && deviceModel.isNotEmpty)
            'device_model': deviceModel,
          if (osVersion != null && osVersion.isNotEmpty)
            'os_version': osVersion,
        }),
      );

      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return (
            status: DeviceCheckinStatus.success,
            model: DeviceCheckinModel.fromJson(json),
          );
        case 401:
          logger.w('[STB] checkin rejected token: ${response.body}');
          return (status: DeviceCheckinStatus.unauthorized, model: null);
        case 403:
          logger.w('[STB] checkin subscriber blocked: ${response.body}');
          return (status: DeviceCheckinStatus.suspended, model: null);
        case 409:
          logger.w('[STB] checkin device unassigned: ${response.body}');
          return (status: DeviceCheckinStatus.unassigned, model: null);
        default:
          logger.w(
            '[STB] checkin HTTP ${response.statusCode}: ${response.body}',
          );
          return (status: DeviceCheckinStatus.failed, model: null);
      }
    } catch (e) {
      logger.w('[STB] checkin request error: $e');
      return (status: DeviceCheckinStatus.failed, model: null);
    }
  }

  /// Acknowledges an executed MDM command (`POST /command/{id}/ack`) with
  /// `ACKED` on [success], `FAILED` otherwise. Returns true if the backend
  /// accepted the ack. Unacked commands are redelivered on the next check-in.
  Future<bool> ackCommand({
    required String commandId,
    required bool success,
    String? result,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(APIList.commandAck(commandId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'status': success ? 'ACKED' : 'FAILED',
          if (result != null && result.isNotEmpty) 'result': result,
        }),
      );

      if (response.statusCode == 200) return true;
      logger.w(
        '[STB] command ack HTTP ${response.statusCode}: ${response.body}',
      );
      return false;
    } catch (e) {
      logger.w('[STB] command ack error: $e');
      return false;
    }
  }

  String? _extractDeviceId(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['device_id'] is String) {
        return json['device_id'] as String;
      }
    } catch (_) {}
    return null;
  }

  /// Logs in as the operator and returns the session cookie header value
  /// (`tulix_session=...`), or null if login failed.
  Future<String?> _operatorSession() async {
    final res = await _client.post(
      Uri.parse(APIList.operatorLogin),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': _operatorEmail,
        'password': _operatorPassword,
      }),
    );

    if (res.statusCode == 200) {
      final cookie = _extractSessionCookie(res.headers['set-cookie']);
      if (cookie == null) {
        logger.w('[STB] login ok but no session cookie in response.');
      }
      return cookie;
    }

    logger.w('[STB] operator login HTTP ${res.statusCode}: ${res.body}');
    return null;
  }

  String? _extractSessionCookie(String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return null;
    final match = RegExp(r'tulix_session=[^;,\s]+').firstMatch(setCookie);
    return match?.group(0);
  }
}
