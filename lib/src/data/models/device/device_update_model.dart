/// Result of a device update check (`GET /api/device/{id}/update`).
class DeviceUpdateModel {
  final String installedVersion;
  final String latestVersion;
  final bool updateRequired;
  final String? apkDownloadUrl;
  final String? apkSha256;

  const DeviceUpdateModel({
    required this.installedVersion,
    required this.latestVersion,
    required this.updateRequired,
    this.apkDownloadUrl,
    this.apkSha256,
  });

  factory DeviceUpdateModel.fromJson(Map<String, dynamic> json) {
    return DeviceUpdateModel(
      installedVersion: (json['installed_app_version'] ?? '') as String,
      latestVersion: (json['latest_app_version'] ?? '') as String,
      updateRequired: (json['update_required'] ?? false) as bool,
      apkDownloadUrl: json['apk_download_url'] as String?,
      apkSha256: json['apk_sha256'] as String?,
    );
  }
}
