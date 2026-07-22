import 'package:flutter/foundation.dart';

/// Phase of an in-progress MDM-triggered app update.
enum UpdatePhase { downloading, installing }

/// A snapshot of update progress for the overlay.
class UpdateProgress {
  const UpdateProgress(this.phase, [this.value]);

  final UpdatePhase phase;

  /// Download fraction 0..1 while [phase] is [UpdatePhase.downloading]; null
  /// (indeterminate) while installing.
  final double? value;
}

/// Drives the on-screen "Updating…" overlay while an MDM `UPDATE_APP` command
/// downloads and installs a new build. The MDM executor pushes progress here so
/// the user isn't staring at a frozen-looking screen during a background
/// download. `null` = nothing in progress (overlay hidden).
class UpdateProgressController {
  final ValueNotifier<UpdateProgress?> progress =
      ValueNotifier<UpdateProgress?>(null);

  void showDownloading(double fraction) =>
      progress.value = UpdateProgress(UpdatePhase.downloading, fraction);

  void showInstalling() =>
      progress.value = const UpdateProgress(UpdatePhase.installing);

  void hide() => progress.value = null;

  void dispose() => progress.dispose();
}
