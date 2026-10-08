# report — firetv — remote Back trapped in the live player

STATUS: done — reviewed (APPROVE, no HIGH), verified on an Android TV emulator; not yet run on real Fire TV hardware
BRANCH: feat/fire-tv (user chose to stay on it; no new branch). Base: be45c47.

Knowledge applied: android-tv-back-is-a-route-pop, flutter-focusscope-key-handler-and-autofocus-gotchas, flutter-focus-traversal-does-not-cross-stack-into-positioned
Knowledge contradicted: android-tv-back-is-a-route-pop — says the remote's Back reaches Flutter "as an ordinary route pop, not a raw key event a widget can intercept". On this app (Flutter Android embedding, Android TV emulator API 36) Back DOES arrive first as a `LogicalKeyboardKey.goBack` key event that focus nodes can handle — the player's `_inkFocus` handler visibly toggled the controls on every Back press — and only an UNHANDLED key is re-dispatched as the route pop. The entry's conclusion (one PopScope as the authority, no raw Back handler beside it) still holds; its mechanism statement needs "key first, pop only if unhandled".

## Summary

On the `normal` flavor (Fire TV, Android TV, phones) the remote's Back could
not leave the full-screen player (live, VOD, radio). Three things combined:

1. `AppVideoPlayer.build` wrapped the player in `PopScope(canPop: false)` with an
   empty handler, so every route pop was swallowed (this also disabled the
   system back gesture on phones in that player).
2. Raw `goBack` key handlers fought over the key: `_inkFocus` (InkWell around the
   overlay) turned Back into "toggle controls"; `playPauseFocus` moved focus to ←
   then returned `ignored`, so the event bubbled to `_inkFocus`; `arrowBackFocus`
   swallowed it with `skipRemainingHandlers`; the schedule sheet had its own.
3. Every controls show/hide ran `playPauseFocus.requestFocus()` (BlocConsumer
   listener), so the ← highlight was torn back to ⏸ — "← is highlighted but OK
   pauses".

Fix: one Back authority — `PopScope(canPop: !isSeasonsOpen)` in
`VodFullScreen.build`: schedule open → Back closes it; otherwise the route pops.
No focus node in the player handles `goBack` any more, so Android turns the
unhandled key into that pop. Up from ⏸ now moves to ← explicitly (first Up
reveals the controls, like Down already did), so the listener no longer races
it. Player strings are localized.

## Files changed
- `lib/src/ui/widgets/app_video_player/app_video_player.dart` — removed the
  swallowing PopScope and `_inkFocus`'s goBack handler; dropped the now-unused
  `dart:async` import.
- `lib/src/ui/widgets/app_video_player/screens/vod_fullscreen.dart` — PopScope
  Back contract; goBack ignored in `playPauseFocus` / `arrowBackFocus`; schedule
  sheet's goBack handler removed; explicit Up → ←; strings via `context.l`
  (`todaysSchedule`, `sectionSchedule`, `scheduleLoadError`, `retry`,
  `noSchedule`, `badgeLive`). The Stack under the new PopScope is re-indented
  only for the wrapped block (the file is not dart-format clean upstream; a
  whole-file format would have rewrapped unrelated lines).
- `packages/app_localization/lib/l10n/app_{en,fr,es}.arb` + regenerated
  `lib/src/app_localizations*.dart` — new key `todaysSchedule`
  (en "Today's Schedule", fr "Programme du jour", es "Programación de hoy").
- `pubspec.yaml` — dev_dependency `video_player_platform_interface: ^6.6.0`
  (already resolved transitively at 6.6.0; only the lock's dependency marker
  changes).
- `lib/src/ui/widgets/app_scaffold.dart` (added after the first device run) —
  the shell's `goBack` handler now acts on KeyDown only and swallows the up.
  It acted on down AND up: the up of the press that just popped the player
  landed on Home and opened the rail (seen on device, B2), and on pages without
  the rail one press called `context.pop()` twice.
- `lib/src/ui/widgets/app_video_player/widgets/radio_now_playing.dart` (review
  C2) — "ON AIR" → `context.l.badgeOnAir`.
- `test/widgets/player_back_contract_test.dart` — 8 widget tests driving the
  real `AppVideoPlayer` against a fake video platform, through the real pop path
  (`handlePopRoute`) and real key events.

## Decisions
- Back always leaves when the schedule is closed — even with the controls
  showing (user chose this over "first Back hides the controls").
- Up is two-step (reveal, then ←), mirroring the existing Down behaviour, rather
  than reveal-and-focus in one press: one press would race the visibility
  listener's focus request (both resolve in microtasks; the later
  `requestFocus` wins).
- The visibility listener itself is unchanged: with Back gone from the key
  handlers, its only remaining triggers are auto-hide (→ ⏸ is right) and
  reveal-from-hidden (focus is already ⏸).
- `VideoPlayerCubit` is app-wide; the test provides it above the navigator the
  same way, because a route-scoped cubit is closed on pop and its 6 s auto-hide
  timer then throws "Cannot emit new states after calling close".
- Not touched: `live_fullscreen.dart` (not on this path), the STB players (their
  own working PopScope contract), the home shell's Back→menu handler.

## Verification
- Tests first: the new suite fails 7/8 on the old player code (red), passes 8/8
  on the fix. ("Up reaches ←" also passes on the old code with two presses — it
  is coverage, not the repro.)
- `flutter test`: 128/128 pass (re-run after the post-review additions).
- `flutter analyze`: 0 errors; warnings 50 / infos 113 — baseline before the
  change 50 / 114; no new finding in touched files (remaining ones in
  `app_video_player.dart` — unused `live_fullscreen.dart` import, a `print` —
  are pre-existing).

## Learnings candidates
- Flutter on Android TV: Back arrives as a `goBack` KEY first; only if no focus
  node handles it does the embedding issue the route pop. A focus node that
  marks it handled (or a `PopScope(canPop:false)` with an empty handler) traps
  the viewer. Test with `sendKeyDownEvent(goBack, physicalKey: browserBack,
  platform: 'web')` — the default android simulation asserts on a missing
  scanCode for goBack.
- `KeyEventResult.skipRemainingHandlers` is NOT "handled" for the platform — it
  does not stop Android turning Back into a pop (reviewer correction to the
  plan's root-cause list).
- A shell-level `goBack` handler that ignores the event type acts on the key-up
  too: once a pushed route pops on Back's down, the up lands on the page
  underneath and fires its Back action (opened the rail; double pop elsewhere).
- Driving a TV emulator by adb: guard every keypress on the foreground activity —
  if the app is not in front, keys go to the launcher (an un-set-up Google TV
  emulator's OK opens Google account sign-in).
- A BlocConsumer listener that `requestFocus()`es a default control on every
  visibility change silently defeats any explicit focus move made in the same
  key handler (microtask ordering).
- Widget-testing a `video_player` screen: install a fake `VideoPlayerPlatform`
  that emits `initialized` immediately; provide app-wide cubits above the
  navigator, or their timers throw after the route's provider closes them.

## Blockers
none

## Review
`review.md` — APPROVE, no HIGH. Acted on: C1 (device run, below), C2 (radio
"ON AIR" localized), NITs (`if (!didPop && isSeasonsOpen)`, the "Up mirrors
Down" comment). Not acted on (pre-existing, out of scope): C3 test gaps (focus
assertions), C4 unkeyed Positioned siblings in the overlay Stack, S1 stream
URLs logged. C5 (Back now also leaves Radio on the stb flavor) is intended; not
checked on a box. The two post-review additions (app_scaffold KeyDown-only,
radio string) are 6 lines, no security surface — security checklist walked by
the dev: no input parsing, network, storage, secrets or permissions touched.

## Follow-up in the same task: keep the screen awake (user-requested)
Nothing kept a TV awake during playback: `WakelockPlus` was only used by the
two PHONE player screens, and video_player_android 2.8.15 has no
keep-screen-on code — so Fire TV's screensaver/sleep would cut into long live
viewing. `AppVideoPlayer` now holds the wake lock only while
`controller.value.isPlaying`, releases it on pause, and on dispose RESTORES the
state it found (read via `WakelockPlus.enabled` in `initState`, before any
change) — the phone channel page holds its own wake lock while this full-screen
player sits on top of it, so an unconditional disable would have switched that
off. Radio counts as playing, so the TV stays awake on the now-playing screen.
Tests: 3 more (fake `WakelockPlusPlatformInterface`, new dev dep already locked
at 1.2.3): on while playing / off after leaving; off when paused / on when
resumed; a prior wake lock is restored. 2 fail on the code without the change.
Suite 131/131, analyze at baseline. Device (emulator-5554, WPALive_TV):
`dumpsys window` flag on the app window — Home: no KEEP_SCREEN_ON; playing:
KEEP_SCREEN_ON; paused: none; resumed: KEEP_SCREEN_ON; after Back: none
(screenshots W1, W2). Not independently reviewed (small diff; security
checklist walked by the dev — no input, network, storage, secrets; WAKE_LOCK
permission already in the manifest).

## Device verification
Android TV emulator `emulator-5558` (WPALive_TV AVD: 1920x1080 @320, API 36,
leanback), `normal` debug build with all changes. Every key press was guarded
on `topResumedActivity == com.fndtv.videoplayer` (an earlier unguarded run sent
keys to the un-set-up Google TV launcher — backed out, nothing signed in).
Screenshots in `screenshots/`, all read:

| step | result |
|---|---|
| A live, controls hidden → Back | Home (A2) ✓ |
| B live, controls showing ("Programme" in French) → Back | Home, rail closed (B2) ✓ — before the app_scaffold fix the rail opened here |
| C schedule open ("Programme du jour") → Back → Back | schedule closes, still playing (C2) → Home (C3) ✓ |
| D ↑ ↑ → OK | ← highlighted (D1) → Home (D2) ✓ |
| E Radio ("À L'ANTENNE") → Back | Home (E2) ✓ |
| F VOD → Back | NOT reached on device (see below); covered by the `ContentType.dvr` widget test |

logcat: no `FATAL EXCEPTION`, no unhandled Flutter exception, no
"Cannot emit new states" across the runs.

Found, NOT caused by this change (A/B-tested on the committed be45c47 with all
local changes stashed): Back on a freshly launched Home — also Left then Back —
sends the app to the background instead of opening the rail, so the VOD page
could not be reached by remote in this run. Filed as a separate task.
Not declared in platforms.yaml: no real Fire TV / Android TV hardware was used.
