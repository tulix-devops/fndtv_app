# report — stb — sleep/wake black screen

STATUS: implemented; reviewed (2 HIGH found, both fixed); static verification
passed; DEVICE VERIFICATION PENDING (QA, on a real RK3328 box)
BRANCH: feat/tv_version (user chose to stay on it; no new branch)

Knowledge applied: rockchip-video-playback, screen-capture-misses-hardware-overlay,
stb-boot-network-race, flavor-builds, tulix-conventions, android-sdk-path

## Summary

After the box woke from sleep the player showed a black screen until the viewer
pressed Back to leave the page.

`StbSurfacePlayerView` handled the *first* surface creation and nothing else.
`surfaceDestroyed` set a flag and left the engine running, so the decoder kept
writing into a BufferQueue SurfaceFlinger had already abandoned — the reported
logcat spam, whose `api:3` (NATIVE_WINDOW_API_MEDIA) identifies the producer as
the decoder rather than Flutter's EGL renderer. `surfaceCreated` only started an
engine when `pendingUrl` was set, which happens exclusively on the first open
before the surface exists; on a wake it is null, so the newly created Surface
never got a producer at all.

Both ends of the surface lifecycle are now handled: release on destroy, re-open
on create, with the archive position carried across.

## Files changed

- `android/app/src/main/kotlin/com/fndtv/videoplayer/StbSurfacePlayer.kt`
  - The `SurfaceHolder.Callback` is now a named inner class held in a field, so
    `dispose()` can remove it.
  - `surfaceDestroyed`: cancels the watchdog and any posted restart, stops
    stats, captures the resume position, releases the engine.
  - `surfaceCreated`: keeps the `pendingUrl` first-open path; otherwise
    re-opens `currentUrl` on the **current** `engineIndex`.
  - `startEngine(url, playing, resumed)`: guards on `disposed`, defensively
    releases any engine it is about to overwrite, and always starts the engine
    *playing* (see the paused-resume decision below).
  - `advanceEngine`: on a resume, retries the same engine up to `WAKE_RETRIES`
    (3, 3s apart) before entering the normal cascade; releases the engine on
    every exit path including `NO_ENGINE`.
  - `scheduleRestart`: one cancellable, `disposed`/`surfaceReady`-guarded post
    replaces both the wake retry and the bare `main.post` cascade step.
  - `play`/`pause` now emit `playing` events so Dart's state can track them.
  - `ExoPlayerEngine`: `setMediaItem(item, startPositionMs)` with `C.TIME_UNSET`
    when there is nothing to restore; `release()` detaches the surface and
    cannot throw.
  - Class doc: a paragraph on why surface lifecycle is load-bearing here.
- `lib/src/ui/widgets/stb_surface_player/stb_surface_player.dart`
  - passes `isLive` in `creationParams`.

## Decisions

- **Fix in native, not Dart.** The surface lifecycle callback is where the
  event actually arrives; a `WidgetsBindingObserver` in Dart would be a second,
  laggier source of truth for the same event.
- **Re-open rather than re-attach.** `setDisplay(newHolder)` would re-attach the
  existing MediaPlayer, but after an arbitrarily long sleep the HLS playlist has
  moved on. Re-opening lands live channels at the live edge.
- **Reuse the engine that was already working** (`engineIndex` untouched)
  instead of re-running the MediaPlayer-then-ExoPlayer cascade from scratch.
- **Engines are always started playing, even when the viewer had paused**, and
  the pause is re-applied once a real frame lands. A paused start is a trap:
  `MediaPlayerEngine` only calls `start()` when asked to play, and
  `MEDIA_INFO_VIDEO_RENDERING_START` — the only first-frame signal on that
  engine — never arrives without it. The watchdog would then fire on a healthy
  player and cascade onto ExoPlayer, the engine the class doc says wedges on
  these feeds. Starting playing also means the viewer gets a visible frame to
  come back to instead of a black rectangle.
- **Bounded same-engine retry on the wake path.** Without it, a box whose Wi-Fi
  has not re-associated at wake could fail both engines and hit `NO_ENGINE`.
  Correction from review: this is belt-and-braces, not the sole guard — Dart's
  `_everHadFrame` (stb_surface_player.dart:211) already blocks the one-way mpv
  hand-off for any page that has ever shown a frame, which covers the reported
  scenario. The retry still matters for a page that never got a first frame.
- **`isLive` from creation params** rather than inferring live-ness from
  `durationMs() == 0`, which is not reliable across both engines.
- Emitting no error event on `surfaceDestroyed`, deliberately: an error there
  would trip `onUnplayable` and hand the page to mpv on every sleep.

## Review round

Independent review (`review.md`) returned REQUEST_CHANGES with 2 HIGH. Both
were real, both are fixed; each was verified against the code before acting.

- **C1 HIGH — unguarded cascade restart.** `main.post { startEngine(...) }` in
  `advanceEngine` had no `surfaceReady` guard and no handle to cancel it, while
  the wake-retry path one branch above did. A box sleeping in that window would
  bind a fresh engine to a destroyed Surface — reproducing the exact BufferQueue
  spam this task exists to remove, for the whole sleep — and leak a decoder on
  wake. This was a gap left in a sibling path of the function being edited.
  FIXED: both paths now go through `scheduleRestart`, which is cancellable and
  guarded on `disposed` and `surfaceReady`.
- **C2 HIGH — watchdog armed on a resume that could never render.** A paused
  resume was a state this change newly made reachable, and it deterministically
  produced ~70s of spinner followed by a cascade to ExoPlayer. FIXED by the
  always-start-playing decision above.
- **C3 MED** — an unprepared MediaPlayer reports position 0, which could wipe a
  good archive position on a second surface cycle. FIXED: only a position > 0
  overwrites the saved one.
- **C4 MED** — no `disposed` flag and an unremovable anonymous callback allowed
  a post-dispose `startEngine`, whose stats runnable re-posts itself forever.
  FIXED: `disposed` checked at every async entry, callback held in a field and
  removed in `dispose()`.
- **C5 MED** — pre-existing: native never emitted `playing:false`, so on the
  MediaPlayer engine a paused viewer could never un-pause (every OK press sent
  another pause). Fixed here rather than deferred, because this change makes
  "paused" a state that must survive a sleep and then be exited.
- **C6 MED** — the `NO_ENGINE` branch leaked its engine. FIXED.
- **C8 LOW** — `ExoPlayerEngine.release()` could throw into the framework from
  inside `surfaceDestroyed`, i.e. crash on sleep. FIXED with
  `clearVideoSurface()` plus `try/catch`, matching MediaPlayer's release.
- **C11 LOW** — `currentAutoplay` and `playbackRequested` were two sources of
  truth. FIXED: `currentAutoplay` deleted.
- **C7, C9, C12, C13, C14 (LOW/NIT)** — all applied: doc corrections, explicit
  control flow, `setMediaItem` start position, `stopStats()` on the retry path.
- **C10 LOW** — `isLive`/`url` captured once at platform-view creation with no
  `didUpdateWidget`. Confirmed not reachable on today's call path (the page
  computes `link` once from a fixed `video`). Left as-is; recorded as a latent
  trap.
- **S1 LOW** — the full stream URL is logged, now more often. Left as-is: Dart
  already logs the same URL (`[player] source: $link`), the URLs come straight
  from the backend `sources` fields with no client-side token, and the QA script
  depends on those lines. Revisit if the backend ever signs stream URLs.
- **S2 LOW, pre-existing and outside the diff** — `usesCleartextTraffic="true"`
  with no `base-config` makes the two-domain allowlist a no-op. Spun off as a
  separate task; NOT addressed here.
- No HIGH security findings. No waiver needed or requested.

## Review round 2

Re-review of the reworked change: **APPROVE**, no HIGH. It confirmed C1 and C2
genuinely closed (C1 structurally — `scheduleRestart` is now the only scheduler
and `startEngine`'s three callers are each gated, so "no engine exists while the
Surface is down" is provable rather than incidental), confirmed the
`C.TIME_UNSET` reasoning, and confirmed 12 of the round-1 findings fixed. Two
MEDIUMs the rework itself introduced or left, both now fixed:

- **M1 — transport controls hit an engine that was still Preparing.** `play`
  and `seekTo` forwarded straight through, and on MediaPlayer those are invalid
  calls during the post-wake spinner. The platform does not throw; it posts
  `MEDIA_ERROR`, which arrives at `setOnErrorListener` with
  `firstFrameSeen == false` and is indistinguishable from the engine failing to
  start — so `advanceEngine` burned a wake retry, and four OK presses would
  cascade the page onto ExoPlayer for no reason. The QA script explicitly asks
  the tester to press OK right after wake, so this was on the path to being
  reported as a new bug. FIXED: before the first frame the handlers record
  intent and leave the engine alone (it is already starting playing).
- **M2 — a `pause` arriving before the first frame was dropped**, leaving
  `playbackRequested == false` while the channel played on. FIXED: it now defers
  into `pauseAfterFirstFrame`. The same pass removed `pendingAutoplay`, which
  the C11 cleanup had missed, so `playbackRequested` really is the single
  source of truth now.

LOWs also applied: `ExoPlayerEngine.release()` uses separate `try` blocks so a
throw from `clearVideoSurface()` cannot strand the player; `position` reports
`pendingSeekMs` while a resume is in flight, so the DVR progress bar no longer
snaps to 00:00 and back (which QA §3 would have read as a FAIL); and the
`WAKE_RETRIES` KDoc figures are corrected — three retries is four attempts, so
~69s on MediaPlayer and ~57s on ExoPlayer, not 54/45.

One LOW accepted rather than fixed: a paused resume emits up to ~2s of audible
audio before the pause lands, because the engine is deliberately started playing
so a frame can be decoded. Muting it would mean adding a volume method to the
`PlaybackEngine` interface for a cosmetic gain. Documented in `qa-verification.md`
under "Expected, NOT a bug" so QA does not file it.

## Verification

- `flutter analyze` — 164 issues, **all pre-existing** in `packages/`; zero in
  either touched file (grep for `stb_surface_player` returns nothing).
- `flutter test` — 116/116 pass.
- `flutter build apk --flavor stb --release` — exit 0, Kotlin compiles clean.
- Device verification: NOT done here. No real box is reachable from this
  workstation (only an API 36 x86_64 phone emulator, which selects the mpv tier
  and cannot exercise this code path). Per the user's decision the signed APK
  goes to QA; the script they follow is `qa-verification.md` in this folder.

## Build

`flutter build apk --flavor stb --release` — exit 0, 32.3s (post-review rebuild).

- Output: `build/app/outputs/flutter-apk/app-stb-release.apk`
- **Signed** with the Tulix release key
  (`CN=Nika Jugheli, OU=Tulix, O=Tulix, L=Tbilisi, C=GE`, SHA-256
  `937c0242270ccd1f808902db97e72be5dee90018b8e6b08b4e9c01c20b9e2684`),
  verified with `apksigner verify --print-certs`. Same key as previous releases,
  so QA can `adb install -r` over an existing RELEASE build without
  uninstalling; over a DEBUG build they must uninstall first.
- ABIs present: `arm64-v8a`, `armeabi-v7a` only — the `isStbRelease` x86
  exclusion fired correctly.
- Size: **75.2 MB**. This contradicts the knowledge base, which records
  "~113 MB -> ~47 MB" for this exact build after the ABI exclusion. The
  exclusion IS working (verified above); the ~47 MB figure is stale. Current
  native payload is ~64 MB uncompressed across the two ARM ABIs: libmpv
  12.4 + 11.7, libflutter 11.3 + 8.3, libapp 9.5 + 10.6 MB.
- `pubspec.lock` is reverted after every build: this workstation's Flutter
  3.41.6 resolves `meta` 1.17.0 / `test_api` 0.7.10 against a lock committed
  with 1.18.0 / 0.7.11. Environment drift, not part of this change — do not let
  it into the commit.

## Learnings candidates

- A Flutter platform view backed by a real `SurfaceView` must handle surface
  **re-creation**, not just creation. The one-shot `pendingUrl` idiom — set
  before the surface exists, consumed on first create — silently covers only the
  first of an unbounded number of create events. Symptom is a black platform
  view after any window stop (sleep, background, screen off) with the Flutter UI
  itself intact, plus `BufferQueue has been abandoned` at `api:3`.
- `api:N` in a `BufferQueueProducer` error identifies the producer: 1 = EGL
  (Flutter's own renderer), 3 = MEDIA (a decoder). It cheaply distinguishes
  "the video surface died" from "the app's surface died".
- Once a class tears down and rebuilds state on an external lifecycle event,
  EVERY posted task in it needs a handle and a guard. The bug found in review
  was not in the new code but in the pre-existing sibling path that the new code
  made dangerous — a bare `main.post` that was harmless while nothing ever
  released the engine.
- `MediaPlayer` on this hardware reports a first frame only via
  `MEDIA_INFO_VIDEO_RENDERING_START`, which requires `start()`. Any design that
  prepares without starting has no liveness signal at all, so a first-frame
  watchdog will misfire on a healthy player. Start playing, then apply the
  paused state once a frame has landed.
- An automatic engine-fallback cascade needs to know whether it is starting cold
  or recovering; on recovery a failure means "too early", not "this engine
  cannot play this stream".
- `ExoPlayer.setMediaItem(item, 0L)` is NOT the same as the default start
  position: 0 pins a live stream to the start of its window. Use `C.TIME_UNSET`
  when there is nothing to restore.

## Blockers

None for the code. Device verification is out of scope for this workstation by
design — the result depends on QA running `qa-verification.md` on a real RK3328
box.

## Open question for the user

`pubspec.yaml` is still at `0.1.15+16`, the same version already on the boxes.
QA sideloading is fine at the same `versionCode`, but the OTA updater compares
`versionCode`, so this build will not present as an update. Bump before handing
it over if it should.
