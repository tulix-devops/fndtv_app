# Task: Verify forceUpdate endpoint & fix if broken (emulator)

- **Repo:** fndtv_app  •  **Branch base:** `feat/tv_version` @ `491d3f6`
- **Mode:** lightweight verify-and-fix (mobile/emulator, no real device)
- **Date:** 2026-07-11

## What "forceUpdate" is here
The set-top-box self-update mechanism, surfaced on **TV only** via the nav-rail
"Updates" item → `TvUpdatesPage`. It is a manual check page (not a blocking
launch gate). `update_required` is the "force" flag; when true it shows
Download → verify SHA-256 → Install.

Flow: `TvUpdatesPage` → `DeviceRepository.checkUpdate(deviceId)` →
`DeviceDataSource.checkUpdate` → operator login (cookie) →
`GET box.dineo.uk/api/device/{deviceId}/update` → `DeviceUpdateModel`.
`deviceId` = local-storage `stb_device_id`, captured at STB registration on splash.

## Verification results (live, done during recon)
- **Server endpoint is HEALTHY.** Operator login → 200 + cookie.
  `GET /device/{id}/update` → 200 with exactly the fields the model parses:
  `installed_app_version, latest_app_version, update_required,
  apk_download_url, apk_sha256`. Bogus id → 404. Contract matches
  `DeviceUpdateModel.fromJson` field-for-field. ✅
- **App-side is BROKEN on emulator/debug.** Root cause chain:
  1. `device_registration_handler.dart:52` hardcodes MAC `DE:AD:BE:EF:00:02`
     for debug builds when the device reports no MAC (all emulators).
  2. Backend deduplicates devices on **Wi-Fi MAC** → returns
     `409 DEVICE_EXISTS` for any repeat of that MAC (confirmed live).
  3. `device_data_source.dart` maps 409 → `alreadyRegistered, deviceId: null`
     (the 409 body carries no device_id).
  4. Handler stores `stb_registered_serial` (so it never retries) but never
     stores `stb_device_id`.
  5. `tv_updates_page.dart:97` reads empty `stb_device_id` →
     `_UpdateStatus.error` → **"Updates unavailable"**. Update check can never run.

## Proposed fix (minimal, debug/emulator only — release untouched)
In `DeviceRegistrationHandler`, replace the shared constant placeholder MAC
with a **unique, persisted, per-install MAC**:
- Store `stb_debug_mac` in LocalStorage; generate once (random,
  locally-administered `02:xx:...`) if absent, reuse thereafter.
- Use it when the real MAC is empty **or** the anonymized `02:00:00:00:00:00`.
- Guard with `kDebugMode` so real boxes keep sending their real hardware MAC.

Effect: each emulator/debug install registers cleanly → 201 → `device_id`
stored → update page reaches the endpoint and shows the real state
(`v… → v1.3.2`, update available).

## Known deeper gap (flag, not fixing now)
Even a real box can't recover its `device_id` if it hits 409 after storage is
cleared/reinstalled, because register's 409 returns no id and there's no
lookup-by-serial endpoint. Proper fix needs backend support (return existing
device_id on 409, or a GET-device-by-serial). Out of scope for this task.

## Steps after approval
1. Implement the debug-MAC fix.
2. `flutter analyze` (fvm).
3. Build debug APK, uninstall+install on Television_4K emulator, launch.
4. Drive D-pad to nav-rail "Updates", screenshot the update page showing the
   real endpoint result. Scan logcat for `[STB]` flow + crashes.
5. Report.

## OUTCOME — ✅ COMPLETE (2026-07-11)
- **Endpoint:** healthy (verified live via curl — see report).
- **Bug:** confirmed reproduced — before fix the emulator got 409 (shared MAC
  collision) → no `device_id` → update page showed "unavailable".
- **Fix applied:** unique persisted debug MAC in `device_registration_handler.dart`.
- **End-to-end on Television_4K_2 (x86_64) emulator, stb flavor:**
  - `[STB] Debug unique MAC used: 02:21:0F:EC:E8:22`
  - `[STB] Device id stored: 7e64499c-4057-4789-9e5a-e9f037d44097`
  - `[STB] Registration done (DeviceRegisterResult.registered)` (201, not 409)
  - Update page renders **"Mise à jour disponible — v0.0.0 → v1.3.2"** with a
    Download button (screenshot `03-update-available.png`). No crashes in logcat.
- **Left uncommitted** per policy (whole device feature is untracked WIP anyway).

### Build/env gotchas hit (documented for next time)
- App has flavors `normal`/`stb` → `flutter build apk` **requires `--flavor`**;
  the device/update native code is in the **stb** flavor (`src/stb/`).
- TV AVDs: `Television_4K` is **32-bit x86** → Flutter APK won't install
  (NO_MATCHING_ABIS). Use `Television_4K_2` (**x86_64**).
- Building with global Flutter 3.41.6 (project pins fvm 3.32.1) triggered
  Kotlin incremental cache corruption (`BasicMapsOwner`). Workaround:
  `kotlin.incremental=false` (used temporarily, then reverted). Proper fix:
  build with fvm 3.32.1.

### Cleanup note
Test device records were created on the provisioning backend during
verification (serials `team-verify-*` and the emulator's
`7e64499c-4057-4789-9e5a-e9f037d44097`). Harmless, but the operator may want to
prune them (no delete endpoint in-app).
