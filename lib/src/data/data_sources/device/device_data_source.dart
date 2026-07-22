import 'dart:convert';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:fndtv/src/core/config/app_config.dart';
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
/// The box authenticates its device calls (registration, update check) with the
/// setopbox API key ([AppConfig.setopboxApiKey], injected at build time) sent as
/// `Authorization: Bearer <key>` — replacing the old embedded operator
/// credentials. Check-in still uses the per-device Bearer token minted at
/// provisioning (a separate credential).
///
/// Uses its own [http.Client] (not the shared app client) so it neither leaks
/// the fnd user bearer token to the box host nor relies on the app's envelope
/// response handling — this REST endpoint signals via the HTTP status.
final class DeviceDataSource {
  DeviceDataSource();

  final http.Client _client = http.Client();

  /// `Authorization` header value for the setopbox API key, or null if no key
  /// was injected at build time (misconfigured build — calls will fail auth).
  String? get _apiKeyAuth {
    if (!AppConfig.hasSetopboxApiKey) {
      logger.w('[STB] FNDTV_SETOPBOX_API_KEY not set — device call will fail '
          'auth. Build with --dart-define-from-file=env/env.production.');
      return null;
    }
    // TODO(auth-scheme): using Bearer for now; backend dev to confirm whether
    // it expects `Authorization: Bearer` or a custom header (e.g. X-API-Key).
    return 'Bearer ${AppConfig.setopboxApiKey}';
  }

  /// Registers the box. On success (201) the response carries the backend
  /// `device_id` (a UUID) — returned here so it can be persisted for later
  /// update checks. The 409 "already registered" response does NOT include it.
  Future<({DeviceRegisterResult status, String? deviceId})> registerSetTopBox({
    required String serialNumber,
    required String macWifi,
    required String osVersion,
  }) async {
    try {
      final auth = _apiKeyAuth;
      if (auth == null) {
        return (status: DeviceRegisterResult.failed, deviceId: null);
      }

      final response = await _client.post(
        Uri.parse(APIList.registerDevice),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': auth,
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
  /// the check couldn't be completed. Sends the setopbox API key (harmless if
  /// the endpoint is public; required if it isn't).
  Future<DeviceUpdateModel?> checkUpdate(String deviceId) async {
    try {
      final response = await _client.get(
        Uri.parse(APIList.deviceUpdate(deviceId)),
        headers: {
          'Accept': 'application/json',
          if (_apiKeyAuth case final auth?) 'Authorization': auth,
        },
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
}
