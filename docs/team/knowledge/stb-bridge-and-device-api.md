---
topic: stb-bridge-and-device-api
platform: [stb]
apps: [fndtv_app]
date: 2026-07-25
source-task: manual (backfill from feat/tv_version work, 2026-07-11..22)
---

# fndtv_app: StbBridge architecture and the device API

## Fact
- All STB-only native code lives in the `stb` source set as `StbBridge.kt`
  (channel `com.fndtv.videoplayer/stb`), registered REFLECTIVELY by the
  shared `MainActivity` (`Class.forName`, silently skipped on `normal`).
  Dart side: `StbSystemService` + `StbNetworkService`, gated
  `appFlavor == 'stb'`. Blocking/root work runs off the platform thread;
  Wi-Fi scan/join has its own `netIo` executor so it can't starve kiosk
  and power calls.
- Device registration/update talks operator-cookie API at
  `box.dineo.uk/api/device/...`. Backend dedupes devices by Wi-Fi MAC:
  debug builds must generate a unique per-install MAC (`stb_debug_mac`),
  else the 2nd+ device gets 409 and no device_id. Known gap: a real box
  that 409s after storage wipe cannot recover its device_id (register
  returns none, no lookup endpoint) — needs backend support.
- Unwanted/disabled app lists live in Dart consts (`kStbUnwantedApps`,
  `kStbDisabledComponents`, `kStbDisabledPackages`); removal is silent by
  owner decision.
- Boot animation: STB splash plays bundled `assets/video/bootanimation.ts`
  via media_kit; home navigation waits for init AND animation end (15s cap).

## Why it matters
The reflective-registration pattern is the reason `normal` builds stay free
of STB code; breaking it breaks mobile. The MAC-dedupe behavior makes
"update page unavailable" a backend-identity symptom, not a UI bug.

## How to apply
New STB native features: add methods to `StbBridge.kt` + mirror in
`StbSystemService`; never import stb classes from shared code. Anything
touching root, device-owner, video, or DVR resume is real-box-only —
emulator results are not verdicts.

## Related
Portfolio: rockchip-video-playback, stb-kiosk-device-owner, flavor-builds
