# QA Test Cases — STB Network Manager, Identity, Radio & On Demand

**Build:** `feat/tv_version` (fndtv_app), **stb** flavor.
**Device:** X88 Pro (any of Pro 10 / 13 / 14 / 15). **Form factor:** Android TV / set-top box, D-pad remote.

Scope = everything added/changed this cycle that needs a **real box** (the
emulator can't exercise device-owner Wi-Fi control, root, real MAC, WPA3, an
Ethernet cable, or a true offline state).

## Legend
- **Priority:** P1 critical · P2 major · P3 minor.
- **Needs:** extra setup a test requires (e.g. a spare Wi-Fi AP).
- Where a step says "should" it's the pass condition; anything else = fail.

## Pre-flight setup (do once before testing)

| # | Item | Why |
|---|---|---|
| S1 | Install the **stb debug/release APK** (`--flavor stb`). If replacing a build, `adb uninstall com.fndtv.videoplayer` first (debug/release signatures differ). | Correct flavor gates all of this. |
| S2 | Provision the app as **device owner**: factory-fresh box (no Google account) → `adb shell dpm set-device-owner com.fndtv.videoplayer/.MyDeviceAdminReceiver`. Confirm with the network page showing the Wi-Fi/Wired buttons (see TC-NET-08). | Device-owner unlocks Wi-Fi management (`canManage`). |
| S3 | Confirm **root** availability (`adb shell su -c id` → `uid=0`) OR device-owner from S2. Either enables Wi-Fi control. | Fallback path + scan permission self-grant. |
| S4 | Have a **second Wi-Fi network** available (known SSID + password) to join, plus one **open** network if possible, and ideally one **WPA3-only** AP. | Join test cases. |
| S5 | Have an **Ethernet cable** available to plug/unplug. | Wired toggle + ethernet status. |
| S6 | Know the box's **real serial + Wi-Fi MAC** (from the sticker / `adb shell getprop ...`) to verify the on-screen values. | Identity verification. |

> **Known gating (not bugs):** device **check-in / MDM / DRM** are dormant
> until the backend mints a per-device token (`stb_device_token`); the box
> currently self-registers only. So TC-API-* verify registration + the
> dormant-checkin behavior, not live MDM.

---

## A. Device identity display

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-ID-01 | P1 | App on any main tab (Home/Live/…) | Look top-right | One **info block**: clock (HH:mm) on line 1, `Serial number: <value>` on line 2. No yellow underline under any text. |
| TC-ID-02 | P1 | S6 known serial | Compare the block's serial to the sticker/`getprop` value | They match exactly. |
| TC-ID-03 | P2 | — | Switch UI language (rail → language) to FR, then ES | Label localizes: "Numéro de série:" (FR), "Número de serie:" (ES), "Serial number:" (EN). Value unchanged. |
| TC-ID-04 | P2 | — | Open a video (any Live channel) fullscreen | The info block is **hidden** during fullscreen playback; reappears on return. |
| TC-ID-05 | P1 | S6 known MAC | Open **Network** tab → "This device" card | Shows Serial number, **MAC address** (matches real MAC), Device ID (if registered), App version. MAC is NOT in the top clock block. |

## B. Connectivity status & offline overlay

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-NET-01 | P1 | Box online (Wi-Fi or Ethernet) | Open Network tab, read Connection card | Status = **Connected** (green). |
| TC-OFF-01 | P1 | Box online, on Home | Disconnect all networks (unplug Ethernet + forget/disable Wi-Fi, or pull the AP) and wait ≤ ~35s | A **full-screen blocking overlay** appears: "No internet connection", the MAC/serial line, and a **"Set up network"** button. |
| TC-OFF-02 | P1 | Overlay showing (TC-OFF-01) | Read the identity line on the overlay | Serial/MAC shown so phone support works even offline. |
| TC-OFF-03 | P1 | Overlay showing | Focus + select **"Set up network"** | Opens the Network page (full-screen, no nav rail). |
| TC-OFF-04 | P1 | On the Network page opened from the overlay | Reconnect the network (join Wi-Fi / plug Ethernet) | Status flips to Connected; the overlay does **not** re-appear on top of the Network page. |
| TC-OFF-05 | P1 | Back online, leave the Network page | Return to Home | No overlay (auto-dismissed once online). |
| TC-OFF-06 | P2 | Box online | Confirm normal browsing works with no overlay flicker | Overlay never shows while online. |

## C. Network manager — Wi-Fi

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-NET-08 | P1 | Device-owner OR root (S2/S3) | Open Network tab, look at Connection card | **Wi-Fi / Wired** mode buttons are visible (management enabled). |
| TC-NET-09 | P2 | Neither device-owner nor root | Open Network tab | Mode buttons **hidden**, network rows not selectable — status-only degrade (no crash). |
| TC-NET-10 | P1 | S3, S4 | Move Right into content → focus **Scan** → select | Nearby networks list populates (SSID, lock icon, signal bars), sorted by signal. |
| TC-NET-11 | P1 | S4 secured (WPA2) network | Select a locked network → enter password → Connect | Within ~20s Status = Connected, SSID shown; the row shows the connected check. |
| TC-NET-12 | P1 | S4 open network | Select an open (unlocked) network | Joins directly (no password prompt). |
| TC-NET-13 | P2 | S4 WPA2 network | Select it, enter a **wrong** password | After timeout shows "Couldn't connect — check the password"; retry available. |
| TC-NET-14 | P2 | **WPA3-only** AP (S4) | Select it, enter correct password | Joins (SAE). *(On Android-10 boxes without root this may fail — acceptable, documented limitation.)* |
| TC-NET-15 | P3 | On a Wi-Fi network | Reopen Network tab later | Current SSID + IP shown in the Connection card. |

## D. Network manager — Ethernet & Wired toggle

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-ETH-01 | P2 | Ethernet **unplugged** | Open Network tab → Ethernet card | "No cable detected". |
| TC-ETH-02 | P2 | Ethernet **plugged** (S5) | Reopen Network tab | Ethernet card shows cable connected + an IP address. |
| TC-WIR-01 | P1 | Device-owner/root, **cable plugged** | Select **Wired** mode button | Wi-Fi turns off, box stays online via Ethernet (Status still Connected). |
| TC-WIR-02 | P1 | **No cable** plugged | Select **Wired** mode | A warning appears first ("No cable detected — the box will go offline. Continue?"); Cancel aborts, Confirm proceeds and box goes offline (→ overlay). |
| TC-WIR-03 | P2 | On Wired, cable in | Select **Wi-Fi** mode | Wi-Fi turns back on and reconnects. |

## E. Navigation & focus (UX)

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-NAV-01 | P1 | Box **online**, on Home | Rail → select **Network** | Network opens **inline**: nav rail stays visible, **Network** highlighted (not About). |
| TC-NAV-02 | P1 | On the inline Network tab, focus on rail | Press **Right** | Focus moves into the content (Scan / cards); rail auto-hides, "Menu" hint shows bottom-left. |
| TC-NAV-03 | P1 | Focus in Network content | Press **Left** (or Back) | Returns to the nav rail with Network still highlighted — no "stuck" feeling. |
| TC-NAV-04 | P2 | On inline Network tab | Select another tab (Home/Live) | Switches normally; no leftover network state. |
| TC-NAV-05 | P2 | Box **offline** (overlay CTA path) | From the overlay open Network | Opens **full-screen** (no rail); Back returns to the app. |
| TC-OD-01 | P1 | On Demand has ≥ 2 items (may need a language with more VOD) | Open **On Demand**, move focus poster→poster back and forth | Posters do **not** twitch/resize on focus change; only the red ring + glow appear/disappear. |
| TC-OD-02 | P2 | On Demand item focused | Select it | Opens the video player and plays. |

## F. Radio now-playing

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-RAD-01 | P2 | A radio station that broadcasts ICY metadata | Play a radio channel, wait for a track change | The current track (Title / Artist) shows under **ON AIR** on the full player. |
| TC-RAD-02 | P3 | Radio playing with metadata | Return to a tab so the mini-bar shows | The mini-bar subtitle shows the live track (falls back to the brand line when no metadata). |
| TC-RAD-03 | P2 | Radio playing | Switch to a different station | The previous track clears immediately; the new station's track appears when it sends one. |
| TC-RAD-04 | P3 | Station with **no** ICY metadata | Play it | No track line shown (station name + ON AIR only) — no error/placeholder. |

## G. Box API / provisioning (dormant paths)

| ID | Priority | Preconditions | Steps | Expected |
|---|---|---|---|---|
| TC-API-01 | P2 | Fresh box, first launch, online | Launch, check logs `adb logcat -s flutter \| grep STB` | `[STB] Registering …` then `Registration done` (201 or 409 already-registered); a Device ID is stored. |
| TC-API-02 | P2 | After TC-API-01 | Open Network tab → This device | Device ID (UUID) is displayed. |
| TC-API-03 | P3 | No provisioning token yet | Check logs on launch | `[STB] No device token; skipping check-in.` (check-in dormant by design). |
| TC-API-04 | P2 | Registered box | Rail → **Updates** → check | Update check completes (public endpoint, no login); shows up-to-date or an available update. |

## H. Regression / smoke (must still pass)

| ID | Priority | Steps | Expected |
|---|---|---|---|
| TC-REG-01 | P1 | Launch app | Boots to Home, no crash. |
| TC-REG-02 | P1 | Play a Live channel | Video plays (media_kit/mpv on STB). |
| TC-REG-03 | P2 | Kiosk: press Home / try to open Settings | Stays in FNDTV; system settings blocked (device-owner). |
| TC-REG-04 | P2 | Switch language EN/FR/ES across tabs | UI + channel lists refilter; no missing strings. |
| TC-REG-05 | P3 | Leave idle ~20 min | Power guard prompts, then sleeps (if configured). |

---

## Reporting template (per failed test)

```
Test ID:
Device model + Android version:
Provisioning: [device-owner? rooted? subscriber assigned?]
Network: [Wi-Fi SSID / Ethernet / offline]
Steps to reproduce:
Expected:
Actual:
Screenshot / screen-record:
Logcat snippet: adb logcat -s flutter StbBridge
```

## Notes for QA

- Most **management** cases (C, D) require **device-owner or root** — if the
  box is neither, expect the status-only degrade (TC-NET-09) and skip the
  join/toggle cases.
- **WPA3-only** networks (TC-NET-14) are rare; WPA2/WPA3-transition APs join
  via the normal WPA2 path.
- **Check-in / MDM / DRM** are intentionally inactive until backend token
  provisioning lands — do not raise these as bugs; only registration + update
  check are live.
- Grab **logcat** (`adb logcat -s flutter StbBridge`) for any network/identity
  failure — `[STB]` lines show exactly what the native bridge did.
