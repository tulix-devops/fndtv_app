# STB sleep/wake black screen — plan

Date: 2026-08-24
Branch: TBD (user approval pending)
Repo: fndtv_app  •  Flavor: stb  •  Tier: native SurfaceView (API <= 30)

## Goal

After the box wakes from sleep, the player shows picture again with no button
press. Today it shows black until the user presses Back to leave the page.

## Root cause (established before planning)

`StbSurfacePlayerView` never handles surface **re-creation**.

- `surfaceDestroyed` (StbSurfacePlayer.kt:192) sets `surfaceReady = false` and
  nothing else. The engine keeps decoding into the Surface whose BufferQueue
  SurfaceFlinger just abandoned → the reported logcat spam
  (`dequeueBuffer/queueBuffer: BufferQueue has been abandoned`, `api:3` =
  NATIVE_WINDOW_API_MEDIA, so the producer is the decoder, not Flutter's EGL
  renderer).
- `surfaceCreated` (StbSurfacePlayer.kt:182) only starts an engine when
  `pendingUrl != null`, which is set only at StbSurfacePlayer.kt:250 — the
  first open, before the surface exists. On wake it is null, so the new Surface
  never gets a producer → black.
- Nothing on the Dart side compensates: `_StbSurfacePlayerState` has no
  `WidgetsBindingObserver`, and no error event fires because MediaPlayer does
  not report an abandoned queue as an error.

Sleep is deliberate: `StbPowerGuard` fires `StbSystemService.sleep()` →
`input keyevent 223` after the idle countdown.

## Acceptance criteria

1. Live channel: box sleeps, wakes → picture returns unaided, at the **live
   edge** (not a stale segment).
2. DVR/archive: wakes and resumes within ~2s of where it slept.
3. No `BufferQueue has been abandoned` spam in logcat while asleep.
4. A brief post-wake network outage does **not** exhaust the engine cascade and
   permanently hand the page off to mpv (which is the slow tier on these boxes).
5. `flutter analyze` clean; `flutter test` passes; debug `stb` build succeeds
   (android/ is touched).

## Approach

Native, in the callback that exists for it — `SurfaceHolder.Callback`:

- **`surfaceDestroyed`**: cancel the first-frame watchdog, stop stats, capture
  `positionMs()` and playing state, release the engine, null it. Emit no error
  event (an error would trip the Dart `onUnplayable` → mpv hand-off).
- **`surfaceCreated`**: keep the existing `pendingUrl` path. Otherwise, if
  `currentUrl` is set, this is a re-creation → re-open on the **current**
  `engineIndex` (reuse the engine that already worked; do not re-litigate
  MediaPlayer vs ExoPlayer).
- **Resume position**: carry a `seekToMs` into `startEngine`; applied after
  prepare. Live channels pass 0 and land at the live edge. `isLive` comes from
  a new creation param, sourced from the Dart side's existing `_isLive`
  (`contentType != ContentType.dvr`).
- **Wake-path resilience** (criterion 4): on a re-open triggered by surface
  re-creation, a pre-first-frame failure retries the **same** engine a bounded
  number of times before falling into the normal cascade. Rationale: the box's
  network is not necessarily up the instant it wakes — the same transient
  -becomes-permanent shape as [[stb-boot-network-race]].

## Files expected to touch

- `android/app/src/main/kotlin/com/fndtv/videoplayer/StbSurfacePlayer.kt`
- `lib/src/ui/widgets/stb_surface_player/stb_surface_player.dart` (pass
  `isLive` in `creationParams`)

## Out of scope

- The mpv tier (`StbVideoPlayer`, API >= 31) — it has no lifecycle observer
  either and plausibly has an analogous gap, but it renders through a Flutter
  texture, a different surface contract, and the reported box is on the
  SurfaceView tier. Flag, do not fix.
- `stb_surface_boot_video.dart` (same platform view, but a splash-lifetime
  view that never sleeps mid-play).
- The `compileSdk = 36 // Android 15` stale comment from 2c23eab.

## Verification

Per [[screen-capture-misses-hardware-overlay]], a screenshot **cannot** prove
playback on this hardware — video goes to an overlay plane and captures black
whether or not it works. Verification is therefore logcat-based:

- `StbSurfacePlayer` `first frame on <engine>` after wake,
- the 30s `perf engine=... pos=...` heartbeat advancing after wake,
- absence of `BufferQueue has been abandoned` during the sleep window,
- plus the user's own eyes on the TV for the final call.

Requires a real RK3328 box (`adb connect <ip>:5555`). The attached emulator is
API 36 / x86_64 and would select the mpv tier, so it cannot exercise this path.
