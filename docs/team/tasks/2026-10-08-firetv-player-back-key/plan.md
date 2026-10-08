# Plan — Fire TV live player: remote Back is trapped

Branch: `feat/fire-tv` (user chose to stay on it). Flavor: `normal` (Fire TV,
Android TV, phones). Player: `AppVideoPlayer` → `_CustomPlayerControl` →
`VodFullScreen`.

## Goal
A remote-only viewer can always leave the live / VOD / radio player with Back,
and the on-screen ← control is reachable and works. Amazon Fire TV review
requires Back to return to the previous screen.

## Root cause (from reading the code)
1. `AppVideoPlayer.build` wraps everything in `PopScope(canPop: false)` with an
   empty `onPopInvokedWithResult` — every route pop, including the remote's
   Back, is swallowed forever. (This also blocks the system back gesture on
   phones.)
2. Raw `LogicalKeyboardKey.goBack` handlers fight over the key:
   - `_inkFocus` (InkWell around the overlay) turns Back into "toggle controls";
   - `playPauseFocus` moves focus to ← on Back, then returns `ignored`, so the
     event bubbles to `_inkFocus`, which toggles visibility;
   - `arrowBackFocus` swallows Back (`skipRemainingHandlers`) when the schedule
     is closed.
3. Focus yank: `VodFullScreen`'s `BlocConsumer` listener calls
   `playPauseFocus.requestFocus()` on EVERY visibility change, so whenever the
   controls (re)appear the ← highlight is torn back to play/pause — hence "← is
   highlighted but OK pauses" and "Up never reaches ←".
4. Up from play/pause relies on directional traversal between two `Positioned`
   siblings of a `Stack`, which Flutter does not do reliably
   (KB: flutter-focus-traversal-does-not-cross-stack-into-positioned).

## Back contract after the fix (one authority: a PopScope in VodFullScreen)
| state | Back does |
|---|---|
| schedule sheet open | closes the sheet, stays in the player |
| anything else (controls shown or hidden) | leaves the player |

No widget handles `goBack` as a key any more; the pop reaches the PopScope.
The ← button and OK-on-← leave too. Escape (keyboard) keeps working via the
same pop path.

## Focus
- Up on play/pause → focus ←. Down on ← → play/pause (exists).
- The visibility listener no longer steals focus from ← when the controls show;
  when the controls auto-hide, focus returns to play/pause (so OK on a blank
  screen never exits by surprise).

## Localization (same player)
`Schedule` → `sectionSchedule`; `Today's Schedule` → new key `todaysSchedule`
(en/fr/es); `Could not load schedule` → `scheduleLoadError`; `Retry` → `retry`;
`No programs today` → `noSchedule`; `LIVE` badge → `badgeLive`. Regenerate the
committed `app_localizations*.dart`.

## Acceptance criteria
1. On the TV emulator, from the live player with controls hidden: Back → back on
   the Direct page. Same with controls shown.
2. Schedule open: Back closes it (still in player); Back again leaves.
3. Up from play/pause highlights ←; OK on ← leaves the player.
4. VOD (À la demande) and Radio players also leave on Back.
5. French UI shows "Programme" / "Programme du jour" — no English in the player.
6. `flutter analyze` no new issues; `flutter test` green; widget test drives the
   real pop path (`handlePopRoute`) if a seam is practical.

## Files
- `lib/src/ui/widgets/app_video_player/app_video_player.dart`
- `lib/src/ui/widgets/app_video_player/screens/vod_fullscreen.dart`
- `packages/app_localization/lib/l10n/app_{en,fr,es}.arb` + generated files
- test under `test/widgets/`

## Out of scope
- `live_fullscreen.dart` (not on this path), the STB players (own working
  contract), the home shell's Back→menu behaviour, the D-pad seek ±30 s on live.
