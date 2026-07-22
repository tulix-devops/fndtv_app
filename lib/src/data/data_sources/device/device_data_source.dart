import 'dart:convert';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:fndtv/src/core/config/app_config.dart';
import 'package:fndtv/src/data/models/device/device_checkin_model.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';
import 'package:http/http.dart' as http;

/// Outcome of a set-top box self-provisioning attempt (`POST /api/provision`).
enum ProvisionStatus {
  /// HTTP 201 — device registered/reused; token + config returned.
  provisioned,

  /// HTTP 401 — API key missing, invalid, or revoked.
  unauthorized,

  /// HTTP 403 — API key lacks the `device:provision` scope.
  forbidden,

  /// Any other status or a transport error — retry next launch.
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

  /// Self-provisions the box (`POST /api/provision`). Idempotent: same hardware
  /// reuses the same device. On success (201) the backend mints and returns the
  /// per-device token (+ device id + runtime config) — the token is what
  /// authorises later check-ins.
  ///
  /// The 201 response field names are NOT published in the OpenAPI docs, so the
  /// token/id are parsed defensively (common key variants) — confirm against a
  /// real backend response and tighten.
  Future<({ProvisionStatus status, String? deviceToken, String? deviceId})>
      provisionDevice({
    required String serialNumber,
    String? macWifi,
    String? androidId,
    String? model,
    String? osVersion,
  }) async {
    try {
      final auth = _apiKeyAuth;
      if (auth == null) {
        return (status: ProvisionStatus.failed, deviceToken: null, deviceId: null);
      }

      final response = await _client.post(
        Uri.parse(APIList.deviceProvision),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': auth,
        },
        body: jsonEncode(<String, dynamic>{
          'serial_number': serialNumber,
          if (macWifi != null && macWifi.isNotEmpty) 'mac_wifi': macWifi,
          if (androidId != null && androidId.isNotEmpty) 'android_id': androidId,
          if (model != null && model.isNotEmpty) 'model': model,
          if (osVersion != null && osVersion.isNotEmpty) 'os_version': osVersion,
        }),
      );

      switch (response.statusCode) {
        case 201:
          final json = jsonDecode(response.body);
          return (
            status: ProvisionStatus.provisioned,
            deviceToken: _extractString(json, const [
              'device_token',
              'token',
              'bearer',
            ]),
            deviceId: _extractString(json, const ['device_id', 'id']),
          );
        case 401:
          logger.w('[STB] provision unauthorized (bad/revoked key): ${response.body}');
          return (status: ProvisionStatus.unauthorized, deviceToken: null, deviceId: null);
        case 403:
          logger.w('[STB] provision forbidden (key lacks device:provision scope): ${response.body}');
          return (status: ProvisionStatus.forbidden, deviceToken: null, deviceId: null);
        default:
          logger.w('[STB] provision HTTP ${response.statusCode}: ${response.body}');
          return (status: ProvisionStatus.failed, deviceToken: null, deviceId: null);
      }
    } catch (e) {
      logger.w('[STB] provision request error: $e');
      return (status: ProvisionStatus.failed, deviceToken: null, deviceId: null);
    }
  }

  /// Checks whether a newer app build is available for [deviceId], or null if
  /// the check couldn't be completed. `GET /api/device/{id}/update` is scoped to
  /// the per-device Bearer token (not the setopbox API key), so [deviceToken]
  /// must be the provisioning-minted device token.
  Future<DeviceUpdateModel?> checkUpdate(
    String deviceId, {
    String? deviceToken,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(APIList.deviceUpdate(deviceId)),
        headers: {
          'Accept': 'application/json',
          if (deviceToken != null && deviceToken.isNotEmpty)
            'Authorization': 'Bearer $deviceToken',
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
  /// `ACKED` on [success], `FAILED` otherwise. Authenticated with the box's own
  /// per-device Bearer [deviceToken] (the endpoint is `deviceBearer`-scoped — a
  /// device may only ack commands issued to itself). Returns true if the backend
  /// accepted the ack. Unacked commands are redelivered on the next check-in.
  Future<bool> ackCommand({
    required String commandId,
    required String deviceToken,
    required bool success,
    String? result,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(APIList.commandAck(commandId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $deviceToken',
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

  /// First non-empty string value among [keys] in a decoded JSON map.
  String? _extractString(Object? json, List<String> keys) {
    if (json is! Map) return null;
    for (final key in keys) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}
