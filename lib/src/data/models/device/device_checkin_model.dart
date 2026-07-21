/// Outcome of a device check-in attempt (`POST /api/device/checkin`).
enum DeviceCheckinStatus {
  /// HTTP 200 — state reported; response payload is in [DeviceCheckinModel].
  success,

  /// HTTP 401 — the stored device token was rejected.
  unauthorized,

  /// HTTP 409 DEVICE_UNASSIGNED — the box has no subscriber yet.
  unassigned,

  /// HTTP 403 — the subscriber account is suspended or cancelled.
  suspended,

  /// Any other status or a transport error — retry on next launch/interval.
  failed,
}

/// Response of a successful check-in: the server's view of what this box
/// should be running, plus any MDM commands queued for it.
///
/// NOTE: the OpenAPI spec does not publish the response schema, so the field
/// names below follow the API's snake_case convention as documented in the
/// endpoint description (latest app version + APK URL, DRM token, channel-list
/// URL, pending commands). [raw] keeps the untouched payload so nothing is
/// lost if the server uses different keys — verify against a real provisioned
/// device on first integration and adjust here.
class DeviceCheckinModel {
  final String? latestAppVersion;
  final String? apkDownloadUrl;
  final String? drmToken;
  final String? channelListUrl;
  final List<DeviceCommandModel> commands;
  final Map<String, dynamic> raw;

  const DeviceCheckinModel({
    required this.latestAppVersion,
    required this.apkDownloadUrl,
    required this.drmToken,
    required this.channelListUrl,
    required this.commands,
    required this.raw,
  });

  factory DeviceCheckinModel.fromJson(Map<String, dynamic> json) {
    return DeviceCheckinModel(
      latestAppVersion: _string(json, ['latest_app_version', 'app_version']),
      apkDownloadUrl: _string(json, ['apk_download_url', 'apk_url']),
      drmToken: _string(json, ['drm_token']),
      channelListUrl: _string(json, ['channel_list_url']),
      commands: _commands(json),
      raw: json,
    );
  }

  static String? _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static List<DeviceCommandModel> _commands(Map<String, dynamic> json) {
    final list = json['commands'] ?? json['pending_commands'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) DeviceCommandModel.fromJson(item),
    ];
  }
}

/// A pending MDM command delivered in the check-in response. The known command
/// types are `UPDATE_APP`, `PUSH_CONFIG`, `REBOOT`, `GET_LOGS`, `KIOSK_LOCK`,
/// `KIOSK_UNLOCK`, `WIPE`. After executing (or failing) one, the box must POST
/// `/api/command/{id}/ack`; unacked commands are redelivered on the next
/// check-in.
class DeviceCommandModel {
  final String id;
  final String type;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic> raw;

  const DeviceCommandModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.raw,
  });

  factory DeviceCommandModel.fromJson(Map<String, dynamic> json) {
    return DeviceCommandModel(
      id: (json['id'] ?? json['command_id'] ?? '').toString(),
      type: (json['command'] ?? json['type'] ?? '').toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
      raw: json,
    );
  }
}
