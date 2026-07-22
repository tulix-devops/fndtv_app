/// Build-time app configuration, injected via `--dart-define-from-file`.
///
/// Usage — pass the env file at build/run time so the values compile into the
/// AOT snapshot (they are NOT shipped as a readable asset):
///
/// ```
/// flutter build apk --flavor stb --release \
///   --dart-define-from-file=env/env.production
/// ```
class AppConfig {
  AppConfig._();

  /// Set-top box API key (env key `FNDTV_SETOPBOX_API_KEY`). Authorises the
  /// box's device calls (registration, update check) via
  /// `Authorization: Bearer <key>`, replacing the old embedded operator
  /// credentials. Empty when a build forgot to pass the env file — device
  /// calls then fail auth (and log a warning) rather than crash.
  static const String setopboxApiKey =
      String.fromEnvironment('FNDTV_SETOPBOX_API_KEY');

  /// Whether the API key was injected at build time.
  static bool get hasSetopboxApiKey => setopboxApiKey.isNotEmpty;
}
