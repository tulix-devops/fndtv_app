# FNDTV documentation

Reference docs for the set-top box (STB) integration and other app subsystems.

## Contents

| Doc | What it covers |
|-----|----------------|
| [device-registration.md](device-registration.md) | How the box registers itself by serial number on startup — the box API, the operator-session auth flow, and the native serial/MAC readers. |
| [stb-kiosk-build.md](stb-kiosk-build.md) | The `stb` build flavor that turns the app into a set-top box kiosk (home launcher, boot auto-start, device admin, self-upgrade) and the boot-video provisioning asset. |

## Quick orientation

- The app is a Flutter Android TV + mobile IPTV/OTT app. On a real set-top box
  it ships as the **`stb` flavor** (see [stb-kiosk-build.md](stb-kiosk-build.md)).
- On first launch the box **self-registers** with the provisioning backend at
  `https://box.dineo.uk` (see [device-registration.md](device-registration.md)).

> Once product flavors exist, Android builds require a `--flavor`. Use
> `flutter run --flavor normal` for day-to-day development.
