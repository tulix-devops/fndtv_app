# STB Device Identity Display + Network Manager — Design

**Date:** 2026-07-22 · **Status:** approved in brainstorming, pending spec review
**Scope:** `stb` flavor only (kiosk boxes where FNDTV is the launcher and Android
Settings is blocked). `normal` flavor and non-TV form factors are unaffected.

## Why

FNDTV ships as the kiosk launcher on rooted AOSP boxes (X88 Pro family).
Kiosk maintenance disables the TV Settings main activity, so a box with wrong
or missing Wi-Fi is a brick the user cannot fix. Support also needs the box
identity (MAC / serial / device id) readable off the screen — it's how devices
get found and assigned in the Box App admin (see `docs/box-api-adoption.md`).

Two features, shipped together, pre-enrollment:

1. **Device identity display** — MAC + serial (+ backend device id when known)
   visible on all screens and detailed on the Network page.
2. **Network manager** — connectivity observer, offline overlay, and a
   full in-app Wi-Fi manager (scan/join) with a Wired ⇄ Wi-Fi switch.

## UX

### Nav + Network page

- New nav-rail action item **Network** (index 7, after Updates). Opens a
  pushed full-screen page exactly like `TvUpdatesPage` (same
  `requestNavFocus()` return pattern).
- Layout, two columns:
  - **Left:** Connection card — Wi-Fi ⇄ Wired toggle, status
    (connected/offline), SSID, IP; Ethernet card — cable link state, IP;
    **This device** card — MAC, serial, device id (when stored), app version.
  - **Right:** Available networks list — SSID, lock icon, signal bars, D-pad
    focus, Scan/refresh action. Selecting a secured network opens password
    entry (system TV IME; a custom D-pad keyboard is a later fallback if some
    firmware lacks an IME — v1 relies on the system keyboard).

### Identity badge (all screens)

- Rendered once at `AppScaffold` level, top-right, stacked under the existing
  TV clock: one dim small line — `MAC A4:… · SN X88P14-…`. Device id is NOT in
  the badge (too long); it lives in the Network page card.

### Offline overlay

- When the observer says offline: full-screen blocking overlay — "No internet
  connection", the MAC/SN line (support works even offline), one focused CTA
  **Set up network** → Network page.
- Never shown on top of the Network page itself. Auto-dismisses on reconnect.

## Architecture (Flutter)

All new pieces are stb-gated (`StbSystemService.isStb`-style guards).

- **`ConnectivityObserver`** (core/services) — merges a `connectivity_plus`
  stream with a debounced reachability probe (HTTP HEAD to the box host
  `/api/health`): interface-up ≠ internet. Probe on every interface change and
  every ~30 s while degraded. Emits `online(type)` / `offline`.
- **`NetworkCubit`** (bloc) — app-provided; state: connection type
  (wifi/ethernet/none), online flag, current SSID/IP, scan results,
  join-in-progress / join-error. Consumed by badge, overlay, Network page.
- **`StbNetworkService`** (core/services) — Dart face of new StbBridge
  methods; fail-soft like `StbSystemService` (log + safe default, never throw).
- **Identity source** — existing `DeviceIdentityService` (serial, Wi-Fi MAC) +
  `kStbDeviceIdKey` from local storage; app version via `package_info_plus`.
- **Overlay mount** — once at `AppScaffold` level; no per-page wiring.

## Native layer (StbBridge, approach C: device-owner APIs primary, root shell fallback)

| Method | Primary (device-owner) | Fallback (root shell) |
|---|---|---|
| `scanWifi()` | `WifiManager.startScan` + `getScanResults` (self-grant location via DO/root `pm grant`) | `cmd wifi list-scan-results` (A11+) |
| `connectWifi(ssid, password?)` | DO-privileged legacy `addNetwork` + `enableNetwork` (works API 29–35 for device owners) | `cmd wifi connect-network <ssid> wpa2 <pass>` (A11+) |
| `setWifiEnabled(bool)` | `WifiManager.setWifiEnabled` (DO-exempt from deprecation block) | `svc wifi enable\|disable` |
| `ethernetStatus()` | `ConnectivityManager` transport ETHERNET link + IP | `ip link` / `ifconfig eth0` parse |

- **Wired toggle semantics:** "Use Wired" = disable Wi-Fi (Ethernet takes over
  when link is up). Guard: if no Ethernet link detected, warn the user
  ("no cable detected — the box will go offline") before switching.
- Android 10 boxes (X88 Pro 10) have no `cmd wifi` — the DO-API path is the
  one that must work there; shell fallback is A11+ only.

## Error handling

- Wrong password: join timeout ~20 s → "Couldn't connect — check the
  password" + retry (reopens password entry).
- Empty scan: "No networks found" + rescan action.
- Neither DO nor root available: join/toggle actions hidden; page degrades to
  status-only display. Never crashes.
- Switch-to-wired with no cable: explicit warning dialog first.

## Localization

App supports **3 languages: English, French, Spanish**
(`packages/app_localization/lib/l10n/app_{en,es,fr}.arb`). Every new
user-facing string ships in all three ARBs, accessed via `context.l.*`
(pattern: the `updates*` keys). New key groups: `network*` (page, cards,
toggle, list, scan, password dialog, errors), `offline*` (overlay), `device*`
(identity labels). No hardcoded UI strings.

## Testing

- Unit: `NetworkCubit` state transitions; shell-output parsers
  (`list-scan-results`, `ip link`) against captured fixtures.
- Emulator smoke: `Television_4K_2` AVD — virtual "AndroidWifi" AP covers
  scan/join happy path + observer/overlay/badge rendering.
- On-device checkpoint (before merge): real X88 box — DO/root paths, Ethernet
  toggle both directions, wrong-password path, offline overlay by pulling
  cable/AP.

## Out of scope (v1)

- Hidden SSID entry, forget/disconnect network, WPS, static IP config,
  captive-portal handling, custom D-pad keyboard, Ethernet configuration
  (display + preference toggle only), any `normal`-flavor UI.

## Risks

- **System IME absent on some firmware** → password entry impossible → v1
  risk accepted; fallback custom keyboard is a fast follow if hit.
- **Scan throttling** (Android 9+ limits foreground scans to 4/2 min) →
  Scan button debounce + show cached results with age note.
- **Firmware variance** in shell output → parsers fixture-tested; DO API is
  primary precisely to minimize shell reliance.
