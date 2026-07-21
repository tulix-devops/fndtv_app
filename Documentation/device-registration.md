# Device registration

On startup the set-top box registers itself with the provisioning backend by
its hardware **serial number**, so operators can track and manage each box.

- **Base host:** `https://box.dineo.uk/api` (separate from the content API,
  `https://fnd.dineo.uk/api`).
- **When:** once on app init, fire-and-forget from the splash screen — it never
  blocks or fails startup.
- **Idempotent:** each serial is registered once; repeats are skipped or return
  `409` (treated as done).

## Auth model

The box backend has two authentication schemes:

| Scheme | Used by | How |
|--------|---------|-----|
| **Operator session cookie** | operator endpoints (incl. `/device/register`) | `POST /api/auth/login` → `Set-Cookie: tulix_session=…` |
| **Bearer device token** | device-facing endpoints (playback, etc.) | `Authorize` with the per-box device token |

`/device/register` is an **operator** action, so registration is a two-step
call: log in as the operator to obtain the `tulix_session` cookie, then POST the
device payload with that cookie.

> The shared app HTTP client is **not** used for these calls — it would attach
> the `fnd.dineo.uk` user bearer token and apply the app's response-envelope
> handling. The box endpoints are plain REST (status in the HTTP code), so
> [`DeviceDataSource`](../lib/src/data/data_sources/device/device_data_source.dart)
> uses its own `http.Client`.

## Endpoints

### `POST /api/auth/login`

```json
{ "email": "…", "password": "…" }
```

`200 OK` + `Set-Cookie: tulix_session=<value>; HttpOnly; Secure; …`. The token is
the cookie — the response body carries the operator record, not a token.

### `POST /api/device/register`

Headers: `Cookie: tulix_session=<value>`, `Content-Type: application/json`.

```json
{
  "serial_number": "X88P14-SN-001",
  "mac_wifi": "AA:11:22:33:44:55",
  "os_version": "Android 13"
}
```

| Status | Meaning | Handler action |
|--------|---------|----------------|
| `201` | Registered | Cache serial, done |
| `409` | Already registered | Cache serial, done |
| `400` | Validation error (e.g. empty `mac_wifi`) | Fail, retry next launch |
| `401`/`403` | Not authenticated / authorized | Fail, retry next launch |

## Flow

```
splash init
  └─ DeviceRegistrationHandler.registerOnInit()   (fire-and-forget)
       ├─ read serial   (DeviceIdentityService → native channel → device_info)
       ├─ if serial already cached → skip
       ├─ read wifi MAC + OS version
       ├─ operator login → tulix_session cookie
       ├─ POST /device/register with cookie + payload
       └─ 201/409 → cache serial;  else → retry next launch
```

## Reading device identity (native)

Serial and MAC come from a native platform channel — reliable on a box, with
`device_info_plus` fallbacks.

- **Channel:** `com.fndtv.videoplayer/device` — registered in
  [`MainActivity.kt`](../android/app/src/main/kotlin/com/fndtv/videoplayer/MainActivity.kt).
- **`getSerialNumber`:** `Build.getSerial()` → `ro.serialno` / `ro.boot.serialno`
  system properties → legacy `Build.SERIAL`. Dart falls back to
  `device_info_plus` `serialNumber`, then the device id.
- **`getWifiMac`:** `/sys/class/net/wlan0/address` → any `wlan*` interface →
  first non-loopback interface → `eth0`. The anonymised `02:00:00:00:00:00` is
  rejected.
- **OS version:** `device_info_plus` → `"Android <release>"`.

> **Privileged-app requirement:** on the real box the app must be a
> **system/privileged app** for `Build.getSerial()` and the MAC read to return
> real values (standard for a pre-installed box app). As an ordinary user app
> both come back blank and registration fails validation (`400`).

## Emulator note

Emulators can't expose a serial (`getSerial()` is blocked) or a Wi-Fi MAC
(privacy/randomization). To exercise the full flow locally:

- the serial falls back to the build id (e.g. `BT2A.260319.001`);
- in **debug builds only**, the handler substitutes a placeholder MAC
  (`DE:AD:BE:EF:00:01`). Release builds send only the real hardware MAC.

## Files

| File | Role |
|------|------|
| [`device_identity_service.dart`](../lib/src/core/services/device_identity_service.dart) | Reads serial, Wi-Fi MAC, OS version |
| [`MainActivity.kt`](../android/app/src/main/kotlin/com/fndtv/videoplayer/MainActivity.kt) | Native serial/MAC reader (`com.fndtv.videoplayer/device`) |
| [`device_data_source.dart`](../lib/src/data/data_sources/device/device_data_source.dart) | Operator login → cookie → register (own `http.Client`) |
| [`device_repository.dart`](../lib/src/data/repositories/device/device_repository.dart) | Repository abstraction |
| [`device_registration_handler.dart`](../lib/src/core/services/device_registration_handler.dart) | Orchestration + once-per-serial cache |
| [`api_list.dart`](../packages/commons/lib/http/api_list.dart) | `operatorLogin`, `registerDevice` URLs |
| [`app_provider.dart`](../lib/src/ui/widgets/app_provider.dart) | Dependency injection |
| [`splash_page.dart`](../lib/src/ui/pages/splash/splash_page.dart) | Fire-and-forget call on init |

## Configuration / TODO

- **Operator credentials** are embedded in
  [`device_data_source.dart`](../lib/src/data/data_sources/device/device_data_source.dart)
  (the box self-registers with no interactive login). Move them to a build-time
  secret if they ever need to rotate.
- **`_registeredSerialKey`** (`stb_registered_serial`) in local storage guards
  against re-registering. Clearing app data forces a re-register (server returns
  `409`, still fine).
