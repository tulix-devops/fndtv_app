import 'package:app_logger/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:local_storage/local_storage.dart';

/// Local-storage key holding the kiosk-lock state (`'1'` when locked). Persisted
/// so an MDM `KIOSK_LOCK` survives a reboot/relaunch — the backend only
/// redelivers a command until it's acked, so once acked the lock must be
/// remembered locally rather than re-fetched.
const String kStbKioskLockedKey = 'stb_kiosk_locked';

/// Holds the box's kiosk-lock state and exposes it to the UI via a
/// [ValueListenable]. A locked box shows a full-screen blocker (see
/// `TvKioskLockOverlay`); the state is driven by the MDM `KIOSK_LOCK` /
/// `KIOSK_UNLOCK` commands and persisted so it outlives a reboot.
class KioskLockController {
  KioskLockController({required LocalStorage localStorage})
      : _storage = localStorage;

  final LocalStorage _storage;

  final ValueNotifier<bool> _locked = ValueNotifier<bool>(false);

  /// Whether the box is currently kiosk-locked. Listen to drive the overlay.
  ValueListenable<bool> get locked => _locked;

  bool get isLocked => _locked.value;

  /// Restores the persisted lock state on startup. Call once at app init.
  Future<void> restore() async {
    try {
      final raw = await _storage.get<String>(kStbKioskLockedKey);
      _locked.value = raw == '1';
      if (_locked.value) logger.w('[STB] Kiosk lock restored — box is locked.');
    } catch (e) {
      logger.w('[STB] Kiosk lock restore error: $e');
    }
  }

  /// Locks (true) or unlocks (false) the box and persists the new state.
  Future<void> setLocked(bool value) async {
    _locked.value = value;
    try {
      await _storage.store<String>(kStbKioskLockedKey, value ? '1' : '0');
    } catch (e) {
      logger.w('[STB] Kiosk lock persist error: $e');
    }
    logger.i('[STB] Kiosk ${value ? 'LOCKED' : 'UNLOCKED'} by MDM command.');
  }

  void dispose() => _locked.dispose();
}
