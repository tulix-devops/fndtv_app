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
