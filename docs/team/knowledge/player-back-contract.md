---
topic: player-back-contract
summary: fndtv_app normal-flavor full-screen player (live/VOD/radio): Back lives in one PopScope in VodFullScreen; Home's Back->rail needs focus inside the content subtree, so a fresh Home's Back exits the app
platform: [androidtv, firetv, mobile]
applies-to: [fndtv_app]
observed-in: [fndtv_app]
date: 2026-10-08
source-task: fndtv_app/docs/team/tasks/2026-10-08-firetv-player-back-key/
---

# fndtv_app: where the full-screen player's Back lives, and Home's open Back bug

## Fact
- **Widget chain (normal flavor):** `AppVideoPlayer` -> `_CustomPlayerControl`
  -> `VodFullScreen`. Live, VOD (`ContentType.dvr` in tests) and Radio all go
  through it; `AppVideoPlayer` is used only by `VideoPlayerPage`. While the
  controller loads or re-initialises `VodFullScreen` is not mounted, so Back
  just pops the route.
- **Back contract = one `PopScope(canPop: !isSeasonsOpen)` in
  `VodFullScreen.build`.** Schedule sheet open -> Back closes it (`_closeDvr`),
  anything else -> the route pops. No focus node in the player handles
  `goBack` (`playPauseFocus` / `arrowBackFocus` return `ignored`; `_inkFocus`
  has no Back handler; the schedule sheet has none). Before 2026-10-08 an
  empty `PopScope(canPop:false)` in `AppVideoPlayer.build` plus
  `_inkFocus` returning `handled` made the player impossible to leave with the
  remote. Mechanism: [[android-tv-back-is-a-route-pop]].
- **Up from ⏸ is two-step:** first Up reveals the controls, second Up moves
  focus to ←. Reason: [[flutter-postframe-callbacks-race-focusmanager-microtask]]
  (the visibility listener's `playPauseFocus.requestFocus()` otherwise wins).
- **The shell's `goBack` handler (`AppScaffold`, `app_scaffold.dart`) acts on
  KeyDown only** ([[flutter-key-handler-acts-on-down-and-up]]); it used to open
  the rail on the up of the press that had just popped the player.
- **Back on the `stb` flavor also leaves the Radio player now** (Radio there
  runs through `AppVideoPlayer`); intended, but not checked on a box. STB
  video players have their own PopScope contract and were not touched.
- **Open bug, not caused by the player change (A/B-tested on `be45c47` with
  local changes stashed):** on a freshly launched Home, Back — also Left then
  Back — sends the app to the background instead of opening the nav rail.
  Home's Back->rail is `AppScaffold.contentFocusNode`, which only fires when
  focus is *inside* the content subtree; a fresh Home has focus elsewhere.
  Filed as a separate task. It also blocks reaching the VOD page by remote on
  an emulator.

## Why it matters
Anyone touching player focus, `AppVideoPlayer`'s wrappers or `AppScaffold`'s
Back handling can silently re-trap the viewer or reopen the rail on the wrong
page. The emulator cannot reach VOD by remote until the Home bug is fixed, so
VOD Back is covered only by the widget test.

## How to apply
- Add Back behaviour to the `PopScope` in `VodFullScreen`, never as a key
  handler on a player focus node.
- Do not wrap `AppVideoPlayer` in a `PopScope(canPop:false)`.
- Regression suite: `test/widgets/player_back_contract_test.dart` (fake video
  platform + real `handlePopRoute`); harness notes in
  [[widget-testing-key-driven-video-player-screens]].
- Verified on an Android TV emulator (API 36) only; not on real Fire TV
  hardware. Run the Back path on a Fire TV before declaring `firetv`.

## Related
[[android-tv-back-is-a-route-pop]];
[[flutter-key-handler-acts-on-down-and-up]];
[[stb-bridge-and-device-api]]
