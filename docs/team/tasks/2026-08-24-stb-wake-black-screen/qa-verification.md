# QA verification — sleep/wake black screen

Build: `app-stb-release.apk` (signed, arm64-v8a + armeabi-v7a)
Fix: the player now releases its engine when the box sleeps and re-opens when
it wakes. Previously it stayed black until you pressed Back.

## 0 — Setup

Install on a **real RK3328 box** (X88pro10 or equivalent). The Android TV /
phone emulators cannot test this: they run API >= 31 and take the mpv engine,
which is a different code path entirely.

```bash
adb connect <box-ip>:5555
```

Release and debug APKs are signed differently, so if the box currently has a
debug build, **uninstall first** — `adb install -r` across a signature change
fails, and the uninstall wipes local storage, so the app will start logged out.

```bash
adb install -r app-stb-release.apk
```

Confirm the box is actually on the affected tier — it must say
`native SurfaceView`, not `mpv`:

```bash
adb logcat -c && adb logcat -s flutter:I | grep "\[player\] API"
```

Expected: `[player] API 30 — native SurfaceView engine` (any API <= 30).
If it says `mpv`, this box does not exercise the fix — find an older box.

## 1 — Live channel (the reported bug)

1. Open any live channel and let the picture run for ~30 seconds.
2. Start a clean log capture:
   ```bash
   adb logcat -c && adb logcat -s StbSurfacePlayer:I flutter:I BufferQueueProducer:E
   ```
3. Put the box to sleep with the remote's power button. (The in-app idle
   timeout is 3 hours, so do not wait for it.) Equivalent over adb:
   ```bash
   adb shell input keyevent 223
   ```
4. Leave it asleep for at least 60 seconds.
5. Wake it with the remote.

### PASS looks like

- **On the TV: picture comes back on its own.** No button press, no black
  screen, no needing to press Back. A few seconds of spinner is expected and
  fine — the stream is being re-opened.
- On sleep, the log shows the engine being let go:
  `StbSurfacePlayer: surface destroyed — releasing mediaplayer at 0ms`
- **No `BufferQueue has been abandoned` lines at all** while the box is
  asleep. That spam is the old bug; a single line of it is a FAIL.
- On wake, the log shows the re-open and a new picture:
  ```
  StbSurfacePlayer: surface re-created — reopening at 0ms
  StbSurfacePlayer: engine=mediaplayer opening http://...
  StbSurfacePlayer: first frame on mediaplayer
  ```
- The heartbeat resumes and `pos=` climbs:
  `StbSurfacePlayer: perf engine=mediaplayer pos=... droppedFrames=...`

### FAIL looks like

- Black screen after wake (the original bug — not fixed).
- `BufferQueue has been abandoned` during sleep (teardown not happening).
- `all engines exhausted` or `surface engines exhausted — falling back to mpv`
  in the log. That means the wake re-open failed three times and the page
  dropped to the slow engine. **Report the surrounding 50 log lines** — the
  likely cause is the box's network not being back yet, and the retry budget
  needs raising.
- Video comes back but is squashed / wrong aspect (regression in the
  anamorphic correction — should not happen, but worth an eye).

## 2 — Live channel, repeated

Repeat step 1 three more times on the same channel without leaving the page.
Each cycle must recover. This catches a resume that only works once.

## 3 — Archive / DVR (resume position)

1. Open an **archive/DVR** program (not a live channel) and let it play to a
   recognisable point — note the on-screen position, e.g. 04:30.
2. Sleep the box, wait 60s, wake it.

### PASS looks like

- Playback resumes **at roughly where it slept** (within a couple of seconds),
  not from the beginning.
- The log carries the position through both ends:
  ```
  StbSurfacePlayer: surface destroyed — releasing mediaplayer at 270000ms
  StbSurfacePlayer: surface re-created — reopening at 270000ms
  ```

### FAIL looks like

- Archive restarts from 00:00 (resume position lost).
- Archive resumes at the live edge or jumps to the end.

## 4 — Paused across a sleep

Do this **twice**: once on an archive program, once on a live channel (OK/Enter
toggles pause on live too).

1. Press OK to pause. Confirm the picture freezes.
2. Sleep the box, wait 60s, wake it.

### PASS looks like

- It comes back **paused on a visible frame** — a still picture, NOT a black
  screen and NOT a spinner. Archive holds the position it slept at; live holds
  a frame from the moment it woke.
- The log shows the deliberate pause after the frame lands:
  ```
  StbSurfacePlayer: first frame on mediaplayer
  StbSurfacePlayer: resumed paused — holding on the first frame
  ```
- **Press OK — it resumes playing.** This is worth checking carefully: pausing
  on the MediaPlayer engine previously left the app unable to un-pause at all
  (the pause state never reached the UI, so every OK press sent another pause).
  That is fixed here; if OK does not resume playback, say so.

### Expected, NOT a bug

- **A short burst of audio (up to ~2s) before the picture freezes.** A paused
  resume deliberately starts the stream playing so a real frame can be decoded,
  then pauses on that frame. Without it the box would sit on a black rectangle
  for over a minute. Please note it if you hear it, but it is by design.
- **Pressing OK while the post-wake spinner is up is safe.** The press is
  recorded and applied when the picture lands; it no longer disturbs the engine
  that is starting.

### FAIL looks like

- Comes back to a spinner that runs for a minute or more, then the picture
  changes engine. This was the pre-fix behaviour of a paused resume.
- Comes back playing when it was paused, or paused when it was playing.
- OK does not resume playback.
- Pressing OK during the post-wake spinner makes the channel fall back to a
  different engine (look for `resume attempt N failed` or `trying exoplayer`).

## 5 — The engine-count invariant

Over a full sleep/wake cycle, every engine start should be accounted for by a
surface event. An engine started outside the surface lifecycle is the bug class
this fix exists to close.

```bash
adb logcat -d -s StbSurfacePlayer:I | grep -cE "engine=.* opening"
adb logcat -d -s StbSurfacePlayer:I | grep -cE "surface re-created|surface destroyed"
```

On a clean run of section 1 the `opening` count should be **1 per wake** (plus
1 for the original channel open). More than that means retries fired — check
for `resume attempt N failed` and report the surrounding lines.

## 6 — Crash check (all scenarios)

```bash
adb logcat -d -t 300 AndroidRuntime:E flutter:W *:S
```

Any `AndroidRuntime` fatal is a FAIL. Attach the output either way.

## What to send back

- Pass/fail per section (1, 2, 3, 4, 5, 6).
- The box model and the `[player] API nn` line.
- The full logcat capture for any failure.
- For section 1, one sentence on what the TV actually did on wake — that is
  the only real proof. A screenshot will NOT show it: on these boxes video
  goes to a hardware overlay plane and `screencap`/`scrcpy` record the video
  area as black whether playback works or not.
