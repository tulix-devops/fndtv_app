# Set-top box kiosk build (`stb` flavor)

On a real set-top box the app runs as a **kiosk**: it *is* the home screen, it
auto-starts on boot, and only this app is visible. That behaviour is isolated in
a dedicated `stb` product flavor so ordinary dev/emulator builds are never
turned into a launcher.

## Flavors

Defined in [`build.gradle.kts`](../android/app/build.gradle.kts):

| Flavor | Purpose |
|--------|---------|
| `normal` (default) | The regular app. Plain `LAUNCHER` entry only. |
| `stb` | The kiosk build. Adds the home-launcher manifest + native components from `android/app/src/stb/`. |

Both share the same `applicationId` (`com.fndtv.videoplayer`) and signing, so
device registration and release signing carry over unchanged.

### Build / run

> Once flavors exist, Android builds **require** a `--flavor`.

```bash
# Day-to-day development (regular app)
flutter run  --flavor normal -d <device>

# Set-top box kiosk build
flutter build apk --flavor stb --release
```

Verify what got merged into a built APK:

```bash
aapt dump xmltree build/app/outputs/flutter-apk/app-stb-debug.apk AndroidManifest.xml
```

The `stb` manifest contains `launchMode=singleTask`, the `LEANBACK_LAUNCHER` and
`HOME` categories, the four components below, and the FileProvider; the `normal`
manifest contains none of them.

## What the kiosk includes

The STB source set lives in **`android/app/src/stb/`** and is compiled *only* for
`stb` builds (additive to `src/main/`).

### Home launcher — "only this app is shown"

[`AndroidManifest.xml`](../android/app/src/stb/AndroidManifest.xml) adds two
intent-filters to `MainActivity` and overrides its launch mode:

- `MAIN` + `LEANBACK_LAUNCHER` — appears as an Android TV launcher app.
- `MAIN` + `HOME` + `DEFAULT` — registers as a **Home screen replacement**, so
  the box boots into FNDTV and Home returns here.
- `android:launchMode="singleTask"` (overrides the main manifest's `singleTop`).

### Holding the HOME role

Being *declared* as a home app is not the same as *being* the home app. The box
only stops showing "Use ___ as Home" when FNDTV actually holds the HOME role,
and there are three mechanisms, in descending order of durability:

| Mechanism | Durability | Needs |
|-----------|-----------|-------|
| `addPersistentPreferredActivity` (device owner) | Permanent, user cannot change it | Device owner — see the warning below |
| No other HOME candidate exists | Permanent while it holds; nothing to choose between | root |
| `cmd package set-home-activity` | **Fragile** — see below | root |

> **`set-home-activity` alone is not enough.** It writes a preferred-activity
> record, and Android drops that record the moment the set of activities
> matching `MAIN`/`HOME` differs from the set present when it was written. So
> uninstalling or disabling a launcher *after* pinning invalidates the pin. That
> was a real field bug: the box came up pinned on one boot and on the chooser
> the next, forever alternating.

[`runStartupMaintenance`](../android/app/src/stb/kotlin/com/fndtv/videoplayer/StbBridge.kt)
therefore runs in a fixed order, and the order is the point:

1. device owner (best effort — usually refused, see below);
2. **neutralise every competing HOME candidate**, then the unwanted apps;
3. only now pin, so the preference is recorded against a set that will not move;
4. verify, and report `kioskReady` / `kioskDurable`.

Competing launchers are **discovered, not listed** — `queryIntentActivities` for
`MAIN`/`HOME` plus `cmd package query-activities` through root. A static list
only ever covers the launchers we have already seen; the one that steals a box is
the one nobody knew to add. This is why the `stb` manifest declares a `<queries>`
block for the HOME intent: without it, Android 11+ package visibility silently
filters other launchers out of the query result and the box happily reports that
nothing is competing with it.

`kioskDurable == false` is the state worth alerting on: the box holds HOME today
but only via a preferred-activity record with other launchers still installed, so
it *will* revert at some future reboot.

> **Device owner cannot be granted after setup.** `dpm set-device-owner` is
> refused on any box that has completed provisioning. It has to happen on a
> factory-fresh box, or FNDTV has to ship in the firmware image as a privileged
> app. For a fleet already in the field the realistic target is therefore "no
> other HOME candidate", not the persistent-preference lock.

### Retrying — [`StbKioskGuard`](../lib/src/core/services/stb_kiosk_guard.dart)

FNDTV *is* the launcher, so it starts before the box has finished booting: `su`
may not have granted yet, PackageManager is still settling. A single pass at
splash — the original design — therefore did nothing at all on a slow boot and
got no second chance until the next reboot. The guard re-runs on a schedule
(0s, 3s, 8s, 20s, 45s) until the box verifiably holds HOME durably, and
re-asserts on `AppLifecycleState.resumed` — which is usually the user having just
answered the chooser, and the one moment the preference is settable.

### Removing preinstalled apps

Two levers, because neither alone works on every box:

- `pm uninstall --user 0` — removes a preinstalled app for the current user; the
  APK stays on `/system`, so a factory reset brings it back. Some firmware marks
  packages non-removable and refuses.
- `pm disable-user --user 0` — cannot be refused, survives a reboot, undone with
  `pm enable`.

Competing launchers take the *reversible* route (disable first): disabling
already stops them resolving HOME, and it leaves the box's own launcher
recoverable. [`kStbUnwantedApps`](../lib/src/core/services/stb_system_service.dart)
is meant to be gone, so it uninstalls first and falls back to disabling.

The pass reads the package list once and skips anything already gone, so a
settled box does one root read and no writes — which matters, because every write
here moves the HOME candidate set.

### Boot auto-start

[`BootReceiver.kt`](../android/app/src/stb/kotlin/com/fndtv/videoplayer/BootReceiver.kt)
listens for `BOOT_COMPLETED` / `QUICKBOOT_POWERON` (permission
`RECEIVE_BOOT_COMPLETED`) and launches `MainActivity` so the box comes straight
up into the app.

### Device admin (lockdown)

[`MyDeviceAdminReceiver.kt`](../android/app/src/stb/kotlin/com/fndtv/videoplayer/MyDeviceAdminReceiver.kt)
+ [`device_admin_rules.xml`](../android/app/src/stb/res/xml/device_admin_rules.xml)
register the app as a device admin for kiosk/lockdown policies.

> **Activation required:** declaring the receiver does **not** grant admin. The
> box must *activate* it via provisioning / MDM or a device-owner setup command
> (e.g. `dpm set-device-owner`). Until then the policies aren't enforced.

### Self-upgrade (OTA) — scaffolded

[`UpgradeActivity.kt`](../android/app/src/stb/kotlin/com/fndtv/videoplayer/UpgradeActivity.kt)
+ [`StartupService.kt`](../android/app/src/stb/kotlin/com/fndtv/videoplayer/StartupService.kt)
+ a `FileProvider` (`${applicationId}.provider`,
[`provider_paths.xml`](../android/app/src/stb/res/xml/provider_paths.xml)) are in
place, but the actual OTA flow (**version check → download APK → install via the
FileProvider**) is a **TODO** — it needs the update endpoint and versioning
contract to be defined first.

## Boot video (provisioning)

`bootanimation.ts` is an MPEG-TS **boot video** played by the box firmware while
it powers on. It is **not** an app asset and **cannot** be set by an APK — a boot
animation/video lives on the system/vendor partition and plays *before any app
starts*. It is stored in [`provisioning/`](../provisioning/) purely as a hand-off
asset for whoever flashes the box firmware. See
[`provisioning/README.md`](../provisioning/README.md).

## Open items

- **OTA logic** — implement once the update endpoint/versioning contract exists.
- **Device-admin activation** — confirm the box provisioning process activates
  the admin receiver (or makes the app device owner).
- **Package name** — the reference manifest used `com.tulix.fndtv`; we kept
  `com.fndtv.videoplayer`. If the firmware/backend expects the former, set a
  per-flavor `applicationId` for `stb`.
- **iOS + flavors** — `--flavor` maps to Xcode schemes on iOS; add matching
  schemes if iOS builds ever pass a flavor. Default iOS builds are unaffected.
