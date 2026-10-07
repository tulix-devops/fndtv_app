# Review: 2026-08-24-stb-wake-black-screen

VERDICT: REQUEST_CHANGES

Scope reviewed: working-tree diff of
`android/app/src/main/kotlin/com/fndtv/videoplayer/StbSurfacePlayer.kt` and
`lib/src/ui/widgets/stb_surface_player/stb_surface_player.dart` on
`feat/tv_version`, read against the full files, `plan.md`, `report-stb.md`,
`qa-verification.md`, and the Dart consumers
(`video_player_page.dart`, `stb_surface_boot_video.dart`).

The core idea is right and matches the class doc: the surface lifecycle is
where the event actually arrives, release-on-destroy / re-open-on-create is
the correct shape, and reusing `engineIndex` rather than re-litigating the
cascade is the right call. Two HIGH findings block: one is a sibling code
path in the very function the diff edits that was left without the guard the
new path got; the other is a state the diff newly makes reachable
(`autoplay == false` at engine start) that the first-frame watchdog was never
designed for.

Line numbers are post-change (current working tree).

## Correctness findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| C1 | HIGH | `StbSurfacePlayer.kt:382` | The cascade's `main.post { startEngine(currentUrl, currentAutoplay) }` has **no `surfaceReady` guard**, while the new wake-retry runnable one branch above (`:360`) does. Failure sequence: an engine fails pre-first-frame (or the 15s watchdog fires) → `advanceEngine` releases it, sets `engine = null`, posts the restart → the box sleeps before the post runs → `surfaceDestroyed` (`:236`) sees `engine == null`, takes the `?: return` at `:245` and does nothing → the posted `startEngine` then runs and binds a brand-new MediaPlayer/ExoPlayer to a **destroyed** Surface. Consequences, all inside the sleep window: `BufferQueue has been abandoned` spam (acceptance criterion 3 fails, and it is the exact symptom this task exists to remove); `armFirstFrameWatchdog` + `startStats` running all night; the watchdog then burns the last cascade step and emits `NO_ENGINE` while nobody is watching; and on wake `surfaceCreated` → `startEngine` overwrites `engine` at `:327` **without releasing it**, leaking a hardware decoder instance for the process lifetime. This is not a remote race — a channel stuck buffering is precisely when `StbPowerGuard`'s idle timer fires. | Guard the posted runnable the same way `:360` is guarded, and store it so it is cancellable: `val next = Runnable { cascadeTask = null; if (surfaceReady && !disposed) startEngine(currentUrl, playbackRequested) }`, cancel it in `surfaceDestroyed` and `dispose()`. Independently, make `startEngine` defensive: `engine?.release()` before `engine = next` at `:327`, so no caller can ever leak one. |
| C2 | HIGH | `StbSurfacePlayer.kt:335` (arm site), `:393-403` (watchdog), `:552-555` (MP start) | A resume with `playbackRequested == false` starts an engine that will never render, but the first-frame watchdog is armed unconditionally. `MediaPlayerEngine.open` only calls `mp.start()` when `autoplay` (`:552`), and `MEDIA_INFO_VIDEO_RENDERING_START` — the only thing that calls `noteFirstFrame()` on this engine — is posted when a frame is actually rendered. For a **paused live channel** (`pendingSeekMs == 0`, so not even a scrub frame) this is deterministic: prepare, no start, no render → 15s watchdog → `advanceEngine` → 3 wake retries (identical, all fail) → ~54s more → cascade to ExoPlayer, i.e. ~70s of spinner. Dart makes it worse: `showSpinner = _error == null && (!_firstFrame \|\| _buffering)` (dart:510) and `_firstFrame` is cleared by the `engine` event (dart:186) and only set by `firstFrame` — so the viewer sees the original bug's symptom (spinner on black) for over a minute. It then lands on ExoPlayer, the engine the class doc says wedges on exactly these interlaced feeds, and the page is stuck there. If ExoPlayer also fails to render in 12s → `NO_ENGINE`; if the page had never produced a frame, that is the one-way mpv hand-off. Paused DVR is the same shape, contingent on whether this Rockchip NuPlayer posts a rendering-start for the post-seek scrub frame — unverified, and the code has no defense either way. QA §4's stated PASS ("comes back still paused, at the same position") is unlikely to be observed. Note this state is newly reachable: OK/Enter toggles play/pause on live channels too (dart:450-456, not gated on `_isLive`), and before this change `autoplay == false` never reached `startEngine`. | In `startEngine`, only arm the watchdog when `autoplay` is true; for a paused start, treat prepared/`STATE_READY` as the success signal — call `noteFirstFrame()` (or a `notePrepared()` that clears the spinner and `resuming`) from `setOnPreparedListener` / `STATE_READY` when `!autoplay`. Also emit `playing:false` so Dart's spinner and toggle state settle (see C5). |
| C3 | MED | `StbSurfacePlayer.kt:246` | `pendingSeekMs = if (isLive) 0L else dying.positionMs()` overwrites the saved position unconditionally, and `MediaPlayerEngine.positionMs()` (`:599-601`) returns `0L` whenever `getCurrentPosition` throws — which it does before the player reaches Prepared. A second destroy/create pair during a resume (common on these boxes when HDMI re-negotiates the mode on wake, and also produced by rapid sleep/wake) therefore silently wipes the archive position and criterion 2 fails with no log trace other than `releasing mediaplayer at 0ms`. ExoPlayer is safe here (its `currentPosition` returns the pending seek target); MediaPlayer, the **primary** engine, is not. | `val pos = dying.positionMs(); if (isLive) pendingSeekMs = 0L else if (pos > 0L) pendingSeekMs = pos` — i.e. never let a not-yet-prepared engine erase a good position. Optionally only trust `pos` when `firstFrameSeen`. |
| C4 | MED | `StbSurfacePlayer.kt:260-269` | `dispose()` gained `cancelWakeRetry()` (good) but there is still no `disposed` flag, `surfaceReady` is left `true`, and the `SurfaceHolder.Callback` added at `:214` is an anonymous object held in no field, so it can never be `removeCallback`ed. Two paths can therefore create an engine after the view is disposed: the uncancellable post at `:382` (C1), and any `surfaceCreated` that arrives post-dispose — both reach `startEngine`, which calls `startStats()` whose runnable re-posts itself on the main looper every 30s **forever** (`:510`), pinning the view, the SurfaceView, the Context and a live decoder, with `events == null` so nothing is visible except audio. | Add `private var disposed = false`; set it first in `dispose()`, also set `surfaceReady = false`, hold the callback in a field and `surfaceView.holder.removeCallback(it)`; early-return on `disposed` in `surfaceCreated`, `surfaceDestroyed`, `startEngine` and `advanceEngine`. |
| C5 | MED | `StbSurfacePlayer.kt:291-292` + `stb_surface_player.dart:361` | `playbackRequested` is now the native source of truth for a resume, but Dart's `_playing` cannot track it on the MediaPlayer engine: `playing` is emitted only at `:554` (on autoplay start) and `:654` (ExoPlayer's `onIsPlayingChanged`) — the `"pause"` handler emits nothing, and `MediaPlayerEngine.pause()` (`:597`) emits nothing. So after the viewer pauses on MediaPlayer, `_playing` stays `true`, and `_togglePlay` (`dart:361`) sends `'pause'` forever — the viewer can never resume. Pre-existing, but the diff promotes "paused" to a state that must survive a sleep and then be exited, which makes the dead-end reachable and user-visible (QA §4 ends here). | Emit `send(mapOf("event" to "playing", "value" to false))` from the `"pause"` branch and `true` from `"play"`, and emit the correct value after a resume settles. Then `playbackRequested` and Dart's `_playing` cannot diverge. |
| C6 | MED | `StbSurfacePlayer.kt:366-376` | The `NO_ENGINE` branch returns without `engine?.release(); engine = null`, unlike both sibling branches (`:356-357`, `:380-381`). The failed engine stays alive and referenced. Pre-existing, but newly load-bearing: with C1 in play it is the engine that `surfaceCreated` overwrites and leaks. | Release and null the engine before sending `NO_ENGINE`. |
| C7 | LOW | `StbSurfacePlayer.kt:366` | On a page that has already cascaded to ExoPlayer (`engineIndex == 1`), the wake budget is 3 x (12s + 3s) ≈ 45s and then `NO_ENGINE` immediately — there is no cascade step left to absorb a slow network. The `WAKE_RETRIES` doc comment (`:721-727`) describes the MediaPlayer figures only. | Either state the ExoPlayer figure in the comment or make `WAKE_RETRIES` engine-relative. No code change strictly required. |
| C8 | LOW | `StbSurfacePlayer.kt:706-709` | `ExoPlayerEngine.release()` has no `try/catch`, unlike `MediaPlayerEngine.release()` (`:610-617`). It is now invoked from inside `surfaceDestroyed` on every sleep, where `p.setVideoSurfaceView(surfaceView)` (`:634`) has registered ExoPlayer's own callback on the same holder: our callback runs first (registered first, in `init`), releases the player and removes Exo's callback mid-dispatch, and the framework then still invokes Exo's `surfaceDestroyed` from its snapshot array against a released player. Believed benign in Media3, but a throw here propagates into the framework and crashes the app on sleep. | `player?.clearVideoSurface()` before `release()`, and wrap in the same `try/catch (_: Throwable)`. QA §5 covers it, but this is cheap insurance. |
| C9 | LOW | `StbSurfacePlayer.kt:193` | `isLive` defaults to `true` when the param is absent, and `stb_surface_boot_video.dart:102-105` does **not** pass it. Correct by luck (the boot video should restart from 0), but the boot view now also gains an automatic re-open on surface re-creation, which the plan lists as out of scope. Worth an explicit note in the KDoc rather than leaving it implied. | Document the default's effect on the boot view, or pass `'isLive': true` explicitly there so the contract is visible at both call sites. |
| C10 | LOW | `stb_surface_player.dart:489-496` | `isLive` (and `url`) are captured once, at platform-view creation; `_StbSurfacePlayerState` has no `didUpdateWidget` and `StbSurfacePlayer` is constructed without a key (`video_player_page.dart:102`). If `widget.link` / `widget.contentType` ever change in place, the native side keeps the stale `isLive` and `currentUrl`, and a wake would restore a position onto the wrong stream. Not reachable on today's call path (the page computes `link` once from a fixed `video`), so this is a latent trap, not a live bug. | Add `didUpdateWidget` that re-invokes `open` on a link change, or key the widget on `widget.link`. |
| C11 | LOW | `StbSurfacePlayer.kt:329` vs `:200` | `currentAutoplay` and `playbackRequested` are now two sources of truth for the same thing. They happen to converge because `startEngine` rewrites `currentAutoplay` from whatever it is passed — but the cascade at `:382` still reads `currentAutoplay`, so a mid-stream pause followed by a pre-first-frame failure restarts playing against the viewer's wish. | Delete `currentAutoplay` and use `playbackRequested` everywhere. |
| C12 | NIT | `StbSurfacePlayer.kt:217-221` | The non-local `return` inside `pendingUrl?.let { }` is **correct** — `let` is inline, so it returns from `surfaceCreated`, which is the intent. It is just hard to read as control flow. | Optional: `val pending = pendingUrl; if (pending != null) { pendingUrl = null; startEngine(pending, pendingAutoplay); return }`. |
| C13 | NIT | `StbSurfacePlayer.kt:692` | `p.seekTo()` before `p.prepare()` works (ExoPlayer masks the seek until the timeline arrives), but `setMediaItem(MediaItem.fromUri(uri), pendingSeekMs)` states the intent directly and has no ordering subtlety. | Optional. |
| C14 | NIT | `StbSurfacePlayer.kt:344-365` | The wake-retry branch does not `stopStats()`. Harmless — the stats runnable hits `val e = engine ?: return` and stops re-posting itself, and `startEngine` → `startStats()` → `stopStats()` clears the stale handle — but it is the only teardown site that skips it, which reads as an oversight. | Add `stopStats()` next to `engine?.release()` at `:356`. |
| C15 | NIT | working tree | `pubspec.lock` shows as modified in `git status` but produces an empty diff (index/mtime artifact). Not part of this change; make sure it does not get swept into the commit. | `git checkout -- pubspec.lock` before committing, or confirm it is genuinely unchanged. |

Kotlin-specific answers to the questions asked:

- **Non-local `return` in `pendingUrl?.let { }` (`:217-221`)** — legal and correct, see C12.
- **`params["isLive"]` in a property initializer (`:193`)** — safe. `params` is a plain constructor parameter, which Kotlin permits in property initializers and `init` blocks; `as? Boolean ?: true` parses as `(params["isLive"] as? Boolean) ?: true` and cannot throw on a wrong-typed value. Declaration order is also correct: `isLive`, `playbackRequested`, `pendingSeekMs`, `resuming`, `wakeRetries`, `wakeRetryTask` (`:193-208`) are all initialized **before** the `init` block at `:210` that calls `openInternal`, so nothing reads a default it should not.
- **Nullability** — no new nullable dereference. `engine ?: return` at `:245`, `engine?.name` at `:354` and `:378` are all safe. `pendingSeekMs.toInt()` at `:549` overflows past ~24.8 days of content; not reachable.

State-machine trace, as requested:

- **`pendingSeekMs` applied to the wrong stream** — no path found. Every URL change goes through `openInternal`, which zeroes it (`:309`) before either stashing `pendingUrl` or starting; a mid-sleep `open` therefore lands on the `pendingUrl` branch with `resumed = false` and a clean seek. The real defect is not wrong-stream but **wrong-value**: C3 lets an unprepared MediaPlayer zero a good position.
- **`playbackRequested` diverging from the engine** — yes, in two directions. Native-side: C11 (the cascade uses `currentAutoplay`). Cross-boundary: C5 (Dart's `_playing` cannot follow it on MediaPlayer). And C2 is the consequence of the engine faithfully honouring `playbackRequested == false` in a place the watchdog does not expect.
- **Reset coverage** — `resuming` is reset on every start path (`:330` takes the parameter, so the cascade's default `false` clears it) and on first frame (`:419`); `wakeRetries` is reset in `surfaceCreated` (`:230`) and `openInternal` (`:310`); `wakeRetryTask` is cancelled in `surfaceDestroyed`, `openInternal` and `dispose`. Those are all correct. The gap is that the **cascade post at `:382` is the one asynchronous task with no field, no guard and no cancel** — C1/C4.
- **Second and third sleep/wake cycle** — holds. Nothing accumulates across cycles: `surfaceCreated` re-zeroes `wakeRetries`, `noteFirstFrame` re-zeroes `resuming`/`pendingSeekMs`, and `surfaceDestroyed`/`startEngine` pair up one release per create. The only cycle-dependent degradation is `engineIndex`, which is monotonic by design — after one wake that exhausts the retry budget, every later wake starts on ExoPlayer with the reduced budget of C7.
- **`dispose()` during a pending wake retry** — handled (`:263`).
- **`surfaceDestroyed` while a wake retry is posted** — handled (`:243`).
- **`surfaceCreated` before a prior release completes** — cannot happen through the callback (they alternate), but *can* happen through C1.
- **A Dart `open` arriving mid-resume** — correct: `openInternal` releases, cancels the retry, and resets all five fields before restarting.

Answer to "can this spuriously trigger the one-way mpv hand-off": **yes, but only when the page has never produced a frame.** `_StbSurfacePlayerState._onEvent` gates the hand-off on `!_everHadFrame` (dart:211), and `_everHadFrame` never resets — so for the reported bug (a channel that was playing before the sleep) a failed wake produces an error overlay with Retry, not an mpv hand-off. The reachable spurious route is C1: an engine started against a dead surface exhausts the cascade **while the box is asleep**, on a page whose first frame never arrived, and the hand-off happens invisibly. Worth recording in the report's Decisions section: the `WAKE_RETRIES` rationale as written ("without it, a wake failure trips the one-way hand-off") is only true inside that never-had-a-frame window — `_everHadFrame` already covers the common case. The retry budget is still worth having, but it is belt-and-braces, not the sole guard.

## Security findings

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| S1 | LOW | `StbSurfacePlayer.kt:332` | The full stream URL is logged at `Log.i` in release builds. Pre-existing, but this change multiplies its frequency: every wake re-opens, and each wake can emit up to four more `engine=... opening <url>` lines (1 + 3 retries), plus the new `surface re-created — reopening at Nms` at `:229`. If the backend ever signs stream URLs with a session token or expiring query parameter, that credential now lands in logcat repeatedly on a device QA is instructed to `adb logcat` (`qa-verification.md:40`). | Confirm whether `sources.primary/hls` carry auth parameters. If they can, log a redacted form (scheme + host + path, query stripped) or drop to `Log.d` behind `BuildConfig.DEBUG`. |
| S2 | LOW (pre-existing, outside the diff) | `android/app/src/main/AndroidManifest.xml:19-20` | `android:usesCleartextTraffic="true"` is set alongside `@xml/network_security_config`, whose only rule is a `domain-config` permitting cleartext for `tulix.com` and `tgn.bozztv.com`. Because there is no explicit `base-config`, the app-level attribute supplies the base default — so cleartext is permitted for **every** host, and the narrow domain-config buys nothing. `SourceModel.isValidUrl` (`source_model.dart:54-57`) accepts any string starting with `http`, so a backend-supplied `http://` URL from any host is played in the clear. Not introduced or touched here; flagged because the pass requires it. | Drop `usesCleartextTraffic` and add an explicit `<base-config cleartextTrafficPermitted="false">` to `network_security_config.xml`, leaving the two domain exceptions. Separate task. |

Every other checklist item was checked and is clean for this diff:

- **Hardcoded secrets** — none. Grepping the diff for `key|token|secret|password|bearer|auth|credential|http://` returns zero matches. No signing config, keystore path or credential appears in either file.
- **Transport** — no endpoint, scheme or TLS setting is added or changed. No `badCertificateCallback`, no `HttpOverrides`, no custom `TrustManager`, no `SSLSocketFactory` anywhere in the diff.
- **WebView** — N/A. No WebView, `javascriptMode`, JS bridge or file-access flag is involved; this is a SurfaceView video path.
- **Android manifest** — not touched by this change. No new component, no `exported` change, no new intent-filter, no new permission. (`REQUEST_INSTALL_PACKAGES` and the two exported components at `:24`, `:73`, `:79` are pre-existing OTA/kiosk surface, unrelated to this task.)
- **Storage** — no credential, token or file written. `pendingSeekMs` is in-memory only and never persisted; nothing touches SharedPreferences or the filesystem.
- **Logging / PII** — the new log lines (`:229`, `:247`, `:354`) carry an engine name and a playback position in ms. No PII, no token, no account identifier. The only concern is the pre-existing URL log, S1.
- **Dependencies** — none added. `pubspec.lock` is flagged modified but its diff is empty (C15); no `build.gradle.kts` change, no new Gradle or pub dependency, so no version-pinning or typosquatting exposure.
- **Injection** — the re-open at `:231` feeds back `currentUrl`, which is the exact string the engine was already given by Dart from `creationParams`; no new source of URL and no concatenation. No deep link, no dynamic URL construction, no SQL or raw query.
- **Roku/BrightScript** — N/A, no `.brs`/`.xml` component in this diff.

## Plan coverage

1. **Live channel wakes to picture at the live edge, unaided** — MET in code. `surfaceCreated:228-231` re-opens `currentUrl` on the existing `engineIndex`, and `isLive` forces `pendingSeekMs = 0` at `:246`, so the re-open lands wherever the playlist's live edge is. Device-unverified (correctly out of the dev's hands; QA §1/§2 covers it).
2. **DVR resumes within ~2s of where it slept** — MET for the ordinary single destroy/create wake: position captured at `:246`, applied at `:549` (MediaPlayer) and `:692` (ExoPlayer), cleared at `:420`. **At risk** from C3 if a second surface cycle lands during the resume, and from C2 if the program was paused.
3. **No `BufferQueue has been abandoned` while asleep** — MET on the happy path (`surfaceDestroyed` releases the engine before returning). **NOT MET** under C1, which puts a live decoder on a destroyed Surface for the whole sleep window — the exact spam this criterion forbids.
4. **A brief post-wake outage does not permanently hand the page to mpv** — MET. `WAKE_RETRIES = 3` at 3s gives ~69s of MediaPlayer grace before the cascade, and Dart's `_everHadFrame` gate (dart:211) independently blocks the hand-off for any page that has ever shown a frame. Two caveats, neither disqualifying: C7 (the ExoPlayer-engine budget is ~45s with no cascade step behind it) and C1 (the one route that can still reach the hand-off spuriously).
5. **`flutter analyze` clean, `flutter test` passes, debug/release `stb` build succeeds** — MET per `report-stb.md:63-94`: 164 analyze issues all pre-existing in `packages/` with zero in either touched file, 116/116 tests, and `flutter build apk --flavor stb --release` exit 0 with signature and ABI evidence. I did not re-run these — this role is report-only and builds are outside my remit — so this is accepted on the report's evidence.

Criteria 3 and 5 aside, the blocking items are C1 and C2, not a missing criterion.

## Notes

- No waiver was communicated to me, and none is needed: there are no HIGH security findings.
- The class documentation added at `:63-72` is accurate and earns its place — the `api:3` / `api:1` distinction in particular is the kind of thing that saves the next reader an afternoon. The fix is consistent with the rest of the doc: it does not disturb the MediaPlayer-first ordering, the anamorphic correction, or the hybrid-composition contract.
- `report-stb.md` is honest about the device-verification gap, and `qa-verification.md` is a good script — but it will not currently catch C1 (needs a channel that is failing to start when the box sleeps) or C3 (needs a double surface cycle on wake). If C2 is fixed, QA §4 becomes the test that proves it; as written, §4 is the test most likely to fail.
- Worth adding to the QA script once C1 is addressed: a `logcat -s StbSurfacePlayer:I` check that the count of `engine=... opening` lines equals the count of `surface re-created` lines over a sleep/wake cycle. Any excess is an engine started outside the surface lifecycle.
- Out-of-scope items from the plan were respected: the mpv tier, `stb_surface_boot_video.dart` and the stale `compileSdk` comment are all untouched. The boot video does inherit the new re-open behaviour by sharing the view type (C9) — benign, but it is a behaviour change to a file the plan listed as out of scope, so it belongs in the report.
- The dev's open question about `pubspec.yaml` still being `0.1.15+16` is a real one and is unresolved in the working tree; it does not affect this review's verdict.

---

## Re-review (round 2)

VERDICT: APPROVE

Scope: the current working-tree diff of
`android/app/src/main/kotlin/com/fndtv/videoplayer/StbSurfacePlayer.kt` and
`lib/src/ui/widgets/stb_surface_player/stb_surface_player.dart`, read against
the full 865-line Kotlin file, `plan.md`, `report-stb.md`, `qa-verification.md`
and the Dart consumers. No files were modified by this review. Line numbers are
post-change (current working tree).

Both HIGH findings are genuinely closed, and closed at the level of the state
machine rather than papered over. C1's `scheduleRestart` is the right shape:
every path that creates an engine now provably runs with `surfaceReady == true`
(see the trace below), which is what criterion 3 actually needs. C2's
always-start-playing resolution is a **better** answer than the one round 1
proposed — it keeps a single first-frame signal, keeps the watchdog meaningful,
and needs no new event type — and I could not break it on either the live or
the DVR resume path.

There are no HIGH findings this round, so this approves. Two MEDIUM findings
sit in the seam the C2 rework opened: the `play`/`pause`/`seekTo` method
handlers were not updated for the new "the engine is always playing, intent is
recorded separately" contract, and on the MediaPlayer engine a method call that
lands before `onPrepared` is not a no-op — the platform converts it into an
`onError`, which `advanceEngine` reads as "this engine cannot play this stream".
Neither blocks; both are small, and I would fix M1 before QA runs section 4 of
the script, because the script instructs the tester to press OK at exactly the
wrong moment.

### Round-1 findings: verified status

| # | Round-1 severity | Status | Evidence |
|---|------------------|--------|----------|
| C1 | HIGH | **FIXED** | `scheduleRestart` (`:477-487`) is the only scheduler; both `advanceEngine` exits use it (`:442`, `:465`); the runnable guards `!disposed && surfaceReady` (`:481`); cancelled in `surfaceDestroyed` (`:291`), `openInternal` (`:381`), `dispose` (`:320`). No bare `main.post` for engine start remains. |
| C2 | HIGH | **FIXED (differently, and better)** | `next.open(url, autoplay = true)` (`:417`) + `pauseAfterFirstFrame` (`:220`, `:412`, `:531-536`). Traced end to end below for both paused-live and paused-DVR. The ~70s spinner and the spurious ExoPlayer cascade are gone. |
| C3 | MED | **FIXED** | `surfaceDestroyed` `:299-304` — `pos > 0L` is required to overwrite; otherwise the saved value is kept. Also correctly leaves `pendingSeekMs` untouched when `engine == null` (`:293`). |
| C4 | MED | **FIXED** | `disposed` (`:237`) set first in `dispose()` (`:316`) with `surfaceReady = false` (`:317`); `SurfaceCallback` held in `holderCallback` (`:240`) and `removeCallback`ed (`:321`); `disposed` checked at `surfaceCreated` (`:260`), `startEngine` (`:400`), restart runnable (`:481`). Immortal-stats-runnable path closed. See N2 for the two sites C4 named that were not literally guarded (harmless). |
| C5 | MED | **FIXED** | `:353-365`; `play` emits `playing:true`, `pause` emits `playing:false`. The un-pause dead end is gone. Residual: M2. |
| C6 | MED | **FIXED** | `:447-449` — the `NO_ENGINE` branch now does `stopStats(); engine?.release(); engine = null` before sending. |
| C7 | LOW | **PARTIALLY FIXED** | The KDoc at `:853-861` now states an ExoPlayer figure, but both numbers are wrong and one case is missing. See L4. |
| C8 | LOW | **FIXED** | `:834-841` — `clearVideoSurface()` then `release()`, inside `try/catch (_: Throwable)`. The fix also removes Exo's own holder callback during `dispose()`, which is a bonus. See L1 for a one-line refinement. |
| C9 | LOW | **FIXED** | `:187-196` documents the `isLive = true` default and names `stb_surface_boot_video.dart` as the caller that relies on it. |
| C10 | LOW | **NOT FIXED — accepted** | Deliberate, rationale in `report-stb.md`. Re-verified: `video_player_page.dart:102-115` builds `StbSurfacePlayer` with no key and a `link` computed once, so the stale-`isLive` trap is still latent, not live. Carried as L6. |
| C11 | LOW | **FIXED** | `grep -rn currentAutoplay android/ lib/` returns nothing. `playbackRequested` is used at `:279`, `:411`, `:482`. Residual: `pendingAutoplay` is a second store on the pending-open path — M2. |
| C12 | NIT | **FIXED** | `:263-268` — explicit `val pending = pendingUrl; if (pending != null) { ...; return }`. |
| C13 | NIT | **FIXED, and the reasoning is CORRECT** | `:807-808`. Confirmed: `setMediaItem(item, startPositionMs)` with `C.TIME_UNSET` resolves to the window's default position, which for a live window is the live edge; `0L` is an explicit seek to the start of the sliding window and would land the viewer minutes behind. Also behaviour-preserving for cold starts — the one-arg `setMediaItem(item)` it replaced is itself defined as passing `C.TIME_UNSET`, so nothing about the non-resume path changed. |
| C14 | NIT | **FIXED** | `stopStats()` now on all three `advanceEngine` exits: `:439`, `:447`, `:462`. |
| C15 | NIT | **RESOLVED** | `git status --porcelain` shows only the two intended files plus the untracked task folder. `pubspec.lock` is clean. |
| S1 | LOW (sec) | **NOT FIXED — accepted** | Deliberate; rationale recorded in `report-stb.md`. Re-checked and I agree it is a reasonable call today — see the security section. |
| S2 | LOW (sec) | **DEFERRED** | Spun off as a separate task; `AndroidManifest.xml` and `network_security_config.xml` are untouched by this diff. |

### Correctness findings (round 2)

**HIGH: none.** I traced every path that can create, release or command an
engine and could not construct a case that breaks an acceptance criterion.

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| M1 | MEDIUM | `StbSurfacePlayer.kt:353-370` (handlers), `:709` (`play`), `:711` (`seekTo`) | **A remote press during the post-wake spinner can cascade the engine.** The `play`/`seekTo` handlers forward straight to the engine, and between the `engine` event and `onPrepared` the MediaPlayer is in the *Preparing* state, where `start()` and `seekTo()` are invalid calls. This does not throw: the platform's JNI shim converts an invalid `start`/`seekTo` into a `MEDIA_ERROR` notification, so `setOnErrorListener` (`:681`) fires, `firstFrameSeen` is still false, and `advanceEngine("MediaPlayer error -38/0")` runs — burning a wake retry, or cascading to ExoPlayer once the budget is gone. Concrete scenario, and it is the one the QA script produces: box wakes paused, Dart's `_playing` is `false`, spinner is up for 1-3s while the HLS playlist is fetched, viewer presses OK to resume → `play` → error → retry. Four impatient presses exhaust `WAKE_RETRIES` and land the page on ExoPlayer, the engine the class doc says wedges on these feeds. On a page that had never produced a frame before the sleep (`_everHadFrame == false`, `stb_surface_player.dart:211`) the tail of that cascade is the one-way mpv hand-off. The mechanism is pre-existing, but this change makes the spinner window recur on **every** wake and puts it on QA section 4's happy path. `seekTo` is the same shape and is reachable on DVR via the right-arrow key, made more tempting by L2. | The engine is already started playing, so a `play` before the first frame has nothing to do — record intent only: `"play" -> { playbackRequested = true; pauseAfterFirstFrame = false; if (firstFrameSeen) engine?.play(); send(...) }`, and the same `firstFrameSeen` gate on `"seekTo"` (folding the request into `pendingSeekMs` instead, so it is not simply lost). Belt and braces: give `MediaPlayerEngine` a `prepared` flag set in `setOnPreparedListener` and make `play`/`seekTo` no-ops until then. |
| M2 | MEDIUM | `StbSurfacePlayer.kt:360-365`, `:266` | **A pause that arrives before the first frame is silently discarded.** `pauseAfterFirstFrame` is the new mechanism for "the viewer wants this paused, apply it when a frame lands", but only `startEngine` (`:412`) and `play` (`:355`) write it — the `pause` handler does not. So: box wakes playing, spinner up, viewer presses OK to pause → `playbackRequested = false`, `engine?.pause()` is a guarded no-op because `isPlaying` is false in Preparing (`:710`), `pauseAfterFirstFrame` stays `false` → `onPrepared` runs `mp.start()` (`:666`) and the channel plays. The press is swallowed. `_playing` ends up `true` (from the `playing:true` at `:667`) so the icon is at least honest and a second press works, but `playbackRequested` is now `false` while the engine plays — the field the KDoc at `:200-204` calls "single source of truth" is wrong for the rest of that playback, and the next sleep/wake will resume paused for no reason the viewer can explain. Same family: the pending-open path at `:266` passes `pendingAutoplay` rather than `playbackRequested`, so a `pause` arriving between `openInternal`'s stash and `surfaceCreated` is discarded the same way. | `"pause" -> { playbackRequested = false; pauseAfterFirstFrame = !firstFrameSeen; engine?.pause(); ... }`. At `:266` use `startEngine(pending, playbackRequested)` and delete `pendingAutoplay` — `openInternal` already sets `playbackRequested = autoplay` at `:386`, so it is pure duplication that the C11 cleanup missed. |
| L1 | LOW | `StbSurfacePlayer.kt:834-841` | The C8 fix put `clearVideoSurface()` and `release()` in the **same** `try` block. If `clearVideoSurface()` throws, `release()` is never reached and `player = null` immediately after drops the last reference — the ExoPlayer instance, its decoder and its playback thread leak for the life of the process. The KDoc's promise ("never throw") is kept; the release is not. Unlikely (both are app-thread calls from `surfaceDestroyed`), but the whole point of that block is the unlikely case. `MediaPlayerEngine.release()` (`:723-730`) has the identical shape, pre-existing and untouched. | Two blocks, or a `finally` that always attempts `player?.release()` in its own `try`. |
| L2 | LOW | `StbSurfacePlayer.kt:371` + `stb_surface_player.dart:167-176` | **The DVR progress bar reads 00:00 for the whole resume window**, which is the exact symptom `qa-verification.md` section 3 lists as a FAIL ("Archive restarts from 00:00 — resume position lost"). `"position"` returns `engine?.positionMs() ?: 0L`; across a wake `engine` is null from `surfaceDestroyed` until `startEngine`, and then `MediaPlayerEngine.positionMs()` catches `IllegalStateException` and returns `0L` until Prepared (`:712-714`). Dart polls every 1s (`dart:72`) and writes it straight into `_position`. A tester who presses a key on wake reveals the bottom bar showing 00:00 and files a false FAIL — and the real position **is** known the whole time, in `pendingSeekMs`. | `"position" -> result.success(engine?.positionMs()?.takeIf { it > 0L } ?: pendingSeekMs)`. Cheap, and it makes the reported position continuous across the wake. |
| L3 | LOW | `StbSurfacePlayer.kt:528-536` + `qa-verification.md` section 4 | The paused resume plays for real between `mp.start()` and the first rendered frame — 1-3s of **audible** audio on every wake for a viewer who deliberately left the box paused, and on DVR it advances the resume point by the audio lead before the pause lands. This is an accepted cost of the C2 design and I would not change the design for it, but it is undocumented and a tester will report "it makes a noise when I wake it" as a bug. | Optional: `setVolume(0f, 0f)` for the `pauseAfterFirstFrame` window and restore it in `noteFirstFrame`. At minimum, add a line to QA section 4's PASS description saying a brief burst of sound before the freeze is expected. |
| L4 | LOW | `StbSurfacePlayer.kt:853-861` | The C7 doc fix states the wrong budgets and omits a case. `wakeRetries < WAKE_RETRIES` allows three *additional* attempts, so a wake gets **four** first-frame windows: 4 x 15s + 3 x 3s = **69s** on MediaPlayer and 4 x 12s + 3 x 3s = **57s** on ExoPlayer, not the 54s / 45s written. Separately, `wakeRetries` is not reset when the cascade advances the engine (`:459-465` keeps `resumed = resuming`), so a wake that burns all three retries on MediaPlayer hands ExoPlayer a budget that is already spent — ExoPlayer gets exactly one 12s attempt and then `NO_ENGINE`. That is a defensible design (the budget is per wake, not per engine) but it is not what the comment describes, and it is the number QA needs when the FAIL branch tells them to report "the retry budget needs raising". | Correct the two figures and add one sentence about the shared-budget behaviour. No code change needed. |
| L5 | LOW | `StbSurfacePlayer.kt:519-537` | `noteFirstFrame()` has no engine identity check — it acts on whatever `engine` currently is, not on the engine that rendered. A stale callback would set `firstFrameSeen` for the *wrong* engine, cancel that engine's watchdog (no recovery for the rest of the session), wipe `pendingSeekMs`, clear the spinner over a black rectangle and pause a player that never started. I checked and this is **currently unreachable**: `MediaPlayer.release()` nulls its listener fields so queued events find no listener, and Media3's `ListenerSet.release()` drops queued events. But the failure mode is severe enough that the one-line guard is worth having, and it stops being free the moment anyone adds an engine. | `private fun noteFirstFrame(source: PlaybackEngine)` and `if (source !== engine) return`. Both call sites (`:672`, `:775`) already sit inside the owning engine. |
| L6 | LOW | `stb_surface_player.dart:489-496` | Carried from C10, accepted as deliberate. `isLive` and `url` are captured once at platform-view creation; there is no `didUpdateWidget` and no key on `StbSurfacePlayer` (`video_player_page.dart:102`). Still not reachable on today's call path. Recorded so the next person who makes `link` mutable finds it. | `didUpdateWidget` that re-invokes `open` on a link change, or key the widget on `widget.link`. |
| N1 | NIT | `StbSurfacePlayer.kt:378-393` | `openInternal` gained `cancelRestart()` but is still the only teardown site that does not `cancelFirstFrameWatchdog()` / `stopStats()`. I convinced myself it is unreachable — the `!surfaceReady` early return implies either "surface never created" (no engine, no watchdog) or "surface destroyed", and `surfaceDestroyed` already cancelled both — and the `surfaceReady` branch cancels via `startEngine`. Asymmetric rather than wrong. | Add both for symmetry so the invariant does not depend on a two-step argument. |
| N2 | NIT | `StbSurfacePlayer.kt:284`, `:427` | C4's suggested fix named four sites for the `disposed` early-return; `surfaceDestroyed` and `advanceEngine` did not get one. Functionally covered — `dispose()` removes the holder callback (`:321`) and releases the engine, and both engines drop their listeners on release, so neither is reachable post-dispose. Noted only because a future reader comparing the code to C4 will wonder. | Optional. |
| N3 | NIT | `StbSurfacePlayer.kt:531-536` | On a paused resume Dart's `_playing` goes false, true, false (the `playing:true` at `:667`/`:767`, then `noteFirstFrame`'s `playing:false`), so the bottom bar's play/pause icon flashes for 1-3s if the controls happen to be visible. And on ExoPlayer `playing:false` is emitted twice — once by `onIsPlayingChanged` from the `engine?.pause()` at `:533` and once explicitly at `:535`. Both harmless; the terminal state is correct either way. | None required. |

### Traces requested

**Paused LIVE resume.** `playbackRequested=false`, `isLive=true`. Sleep →
`surfaceDestroyed` (`:284`): `surfaceReady=false`, watchdog/restart/stats
cancelled, `pendingSeekMs=0` (isLive branch, `:301`), engine released, nulled.
Wake → `surfaceCreated` (`:259`): not disposed, `surfaceReady=true`,
`pendingUrl` null, `currentUrl` set → `wakeRetries=0`,
`startEngine(currentUrl, false, resumed=true)`. `startEngine`:
`pauseAfterFirstFrame=true`, `resuming=true`, `firstFrameSeen=false`,
`open(url, autoplay=true)`, watchdog armed. `onPrepared`: no seek (0),
`buffering:false`, `initialized`, `mp.start()`, `playing:true`.
`MEDIA_INFO_VIDEO_RENDERING_START` → `noteFirstFrame`: `firstFrameSeen=true`,
`resuming=false`, watchdog cancelled, `firstFrame`, then `pause()` +
`playing:false`. Dart terminal state: `_firstFrame=true`, `_buffering=false`,
`_playing=false`, `_everHadFrame=true` → **no spinner, still frame, correct
pause icon, OK resumes.** Matches QA section 4's stated PASS. The watchdog is
armed against an engine that is genuinely trying to render, so C2's failure mode
is gone.

**Paused DVR resume.** Same, plus: `surfaceDestroyed` takes the `pos > 0L`
branch (`:302`) and stores the real position; `onPrepared` applies
`mp.seekTo(pendingSeekMs.toInt())` (`:662`) *before* `mp.start()`;
`noteFirstFrame` zeroes `pendingSeekMs` (`:524`) only after a frame has actually
landed, so a second destroy/create pair mid-resume still finds a good value.
The resume point drifts by the audio lead (L3) and the progress bar reads 00:00
until the first poll after Prepared (L2), but the media position is right. On
ExoPlayer the same trace runs through `setMediaItem(item, 270000)` (`:807-808`).

**Can `scheduleRestart`'s single `restartTask` drop a restart that needed to
happen?** No. Four cancel sites, each provably followed by a guaranteed start:
`scheduleRestart` itself (`:478`, immediately re-posts); `openInternal` (`:381`,
then either `startEngine` or a `pendingUrl` that `surfaceCreated` consumes);
`surfaceDestroyed` (`:291`, then the matching `surfaceCreated` starts on the
current `engineIndex` — which `advanceEngine` had already incremented, so the
cascade step is not lost, only deferred to wake); `dispose()` (`:320`, nothing
should run). The two `advanceEngine` call sites cannot both be live because
`advanceEngine` cancels the watchdog first (`:428`), releases and nulls the
engine on every path, and the error listeners are gated on `!firstFrameSeen`.
Where two restarts could queue, the later one carries the later state
(`engineIndex`, `wakeRetries`) and last-one-wins is the correct resolution. The
runnable capturing `playbackRequested` and `currentUrl` at **run** time rather
than schedule time is also right — the viewer's latest intent wins.

**`startEngine`'s defensive `engine?.release()` (`:403`) — double release, or a
release mid-callback?** Neither. Every caller reaches it with `engine == null`
(`openInternal` `:379-380`; `surfaceCreated` after `surfaceDestroyed` nulled it,
or via `pendingUrl` which `openInternal` nulled; the restart runnable after
`advanceEngine` nulled it), so today it is pure insurance. Both `release()`
implementations null their player and are idempotent, so even a double call is
safe. The mid-callback release that does happen — `advanceEngine` releasing from
inside `onError` — is pre-existing and unchanged in shape.

**Ordering of `firstFrame` then `playing:false`.** Correct, and it cannot
invert: every `send` goes through `main.post` (`:600-602`) so the event channel
is FIFO on one looper, and `noteFirstFrame` itself runs on that looper. Dart
applies `firstFrame` (`dart:191-197`, sets `_firstFrame=true`,
`_buffering=false`, `_everHadFrame=true`) before `playing` (`dart:189-190`).
There is no combination that leaves a stuck spinner:
`showSpinner = _error == null && (!_firstFrame || _buffering)` and both inputs
are cleared by the `firstFrame` handler. The only wrong-icon window is the 1-3s
flicker of N3.

### Security findings (round 2)

No new security findings. Full checklist re-run against the current diff:

| # | Severity | File:line | Finding | Suggested fix |
|---|----------|-----------|---------|---------------|
| S1 | LOW (carried, accepted) | `StbSurfacePlayer.kt:415` | The full stream URL is still logged at `Log.i` in release builds, and this change still multiplies its frequency (one line per wake, up to four per wake with retries). Not fixed, deliberately; the rationale in `report-stb.md` — Dart already logs the same URL, the URLs carry no client-side token, and QA sections 1 and 5 grep for those lines — is sound for today's backend. Left as a standing condition, not a blocker. | Unchanged: if the backend ever signs stream URLs, log a query-stripped form or drop to `Log.d` behind `BuildConfig.DEBUG`. |

- **Hardcoded secrets** — none. Grepping the added lines for
  `key|token|secret|password|bearer|credential|auth` returns zero matches. No
  signing config, keystore path or base64 blob.
- **Transport** — no endpoint, scheme or TLS setting added or changed. No
  `http://` literal, no `badCertificateCallback`, no `HttpOverrides`, no custom
  `TrustManager`/`SSLSocketFactory`.
- **WebView** — N/A. No WebView, `javascriptMode`, JS bridge or file-access
  flag; this is a SurfaceView video path.
- **Android manifest** — untouched (`git status --porcelain` confirms only the
  two source files are modified). No new component, no `exported` change, no
  intent-filter, no permission.
- **Storage** — nothing persisted. `pendingSeekMs`, `playbackRequested` and
  `pauseAfterFirstFrame` are in-memory fields; no SharedPreferences, no
  filesystem write.
- **Logging / PII** — the four new log lines (`:277`, `:305`, `:437`, `:534`)
  carry an engine name, a position in ms and a retry counter. No PII, no token,
  no URL. The only URL log is the pre-existing S1.
- **Dependencies** — none added. `pubspec.yaml`, `pubspec.lock` and
  `android/app/build.gradle.kts` are all unmodified, so no pinning or
  typosquatting exposure. (C15 is now moot: the working tree is clean apart from
  the two files and the untracked task folder.)
- **Injection** — the re-open at `:279` and the restart at `:482` both feed back
  `currentUrl`, which is the exact string Dart passed in `creationParams`. No
  new URL source, no concatenation, no deep link, no SQL or raw query. The one
  new Dart value, `isLive`, is a bool.
- **Roku/BrightScript** — N/A; no `.brs` or component XML in this diff.

### Plan coverage

1. **Live channel wakes to picture at the live edge, unaided** — **MET.**
   `surfaceCreated:276-279` re-opens `currentUrl` on the current `engineIndex`;
   `isLive` forces `pendingSeekMs = 0` at `:301`, and on ExoPlayer `C.TIME_UNSET`
   (`:807`) resolves to the window's default position rather than pinning to the
   start of the sliding window. Device-unverified, as designed — QA sections 1
   and 2.
2. **DVR resumes within ~2s of where it slept** — **MET.** Captured at
   `:299-304` with the C3 guard, applied at `:662` (MediaPlayer) and `:808`
   (ExoPlayer), cleared only after a real frame (`:524`). The C2 rework costs the
   audio-lead drift of L3, well inside the ~2s tolerance. The paused case, which
   round 1 marked at risk, now works.
3. **No `BufferQueue has been abandoned` while asleep** — **MET.** This is the
   criterion C1 was failing, and it is now provable rather than incidental: the
   only three callers of `startEngine` are `openInternal` (gated on
   `surfaceReady` at `:387`), `surfaceCreated` (surface just created), and the
   restart runnable (gated at `:481`). No path constructs an engine while
   `surfaceReady == false`, and `surfaceDestroyed` releases before returning.
4. **A brief post-wake outage does not permanently hand the page to mpv** —
   **MET.** ~69s of same-engine grace before the cascade (L4 corrects the
   arithmetic), plus Dart's `_everHadFrame` gate (`dart:211`) which independently
   blocks the hand-off for any page that has ever shown a frame. The one route
   that can still reach it spuriously is M1, and only on a page that never got a
   first frame before the sleep.
5. **`flutter analyze` clean, `flutter test` passes, `stb` build succeeds** —
   **MET** on the report's evidence (`report-stb.md`: 164 pre-existing issues all
   in `packages/`, zero in either touched file; 116/116 tests; post-review
   `flutter build apk --flavor stb --release` exit 0 in 32.3s, signed, two ARM
   ABIs). Not re-run here — this role is report-only and builds are outside its
   remit.

### Notes

- No waiver was communicated to me and none is needed: there are no HIGH
  security findings.
- The C2 resolution deserves recording as the better answer. Round 1 proposed
  arming the watchdog conditionally and treating "prepared" as success for a
  paused start; that would have added a second liveness signal with different
  semantics per engine and left the paused path untested by the watchdog.
  Always starting playing keeps ONE first-frame signal, keeps the watchdog
  honest on every path, needs no new event type, and gives the viewer a picture.
  The learnings-candidate wording in `report-stb.md` ("Any design that prepares
  without starting has no liveness signal at all") is the generalisable form and
  is worth filing.
- The C13 reasoning about `C.TIME_UNSET` is confirmed correct and is a genuinely
  non-obvious Media3 fact — `setMediaItem(item, 0L)` is *not* the default start
  position. Also worth filing.
- `report-stb.md`'s "## Review round" section is accurate. Every fix it claims,
  I verified in the code; the two it declines (C10, S1) are declined with reasons
  I accept, and S2 is correctly out of this diff.
- QA script gaps for the next pass, all follow-ons from the findings above:
  section 3 should tell the tester to read the position **after** the picture
  returns, not during the spinner (L2); section 4 should say a brief burst of
  sound before the freeze is expected (L3); and section 4's "Press OK — it
  resumes playing" should say to wait for the picture first, or it will hit M1.
  Section 5's engine-count invariant is a good check and now has teeth, since
  C1's fix is exactly what makes the `opening` count equal the
  `surface re-created` count.
- Out of scope but adjacent, noticed while tracing the error path and left
  alone: because `build` gates the platform view on `_error == null`
  (`dart:537`), an error tears the native view down entirely, and `_retry`
  (`dart:378-388`) then invokes `open` on the **old** view's method channel
  before the new one exists. Harmless in practice (the new view auto-opens from
  `creationParams`), pre-existing, and untouched by this change — but it means
  Retry works by accident rather than by design, and the old `_eventSub` is
  never cancelled on the swap.
- The boot video (`stb_surface_boot_video.dart:102-105`) still inherits the new
  re-open-on-surface-recreation behaviour by sharing the view type, with `isLive`
  defaulting to true so it restarts from 0. Benign and now documented at
  `:187-196`, but it is a behaviour change to a file the plan listed as out of
  scope.
- The dev's open question stands and is unresolved in the working tree:
  `pubspec.yaml` is still `0.1.15+16`, so this build will not present as an OTA
  update. Sideloading for QA is unaffected. Not a review matter.
