# Box App API — adoption notes

Backend: `https://box.dineo.uk` — multitenant **D**evice **P**rovisioning
**S**erver + Subscriber Management + MDM for the Android TV box fleet.
Docs UI: `https://box.dineo.uk/docs/box` · OpenAPI: `GET /api/box/openapi.json`.

## The API's mental model

The API separates two worlds with two auth models:

| Auth | Who | Scope |
|---|---|---|
| `operatorSession` (cookie `tulix_session` from `POST /api/auth/login`) | Humans/console (OPERATOR, SUPPORT, SUPERADMIN) | The **whole tenant** — subscribers, fleet, commands incl. WIPE |
| `deviceBearer` (256-bit token, `Authorization: Bearer …`) | The box itself | **That one device** only |

The device token is not something the box asks for — it is **minted by the
server during warehouse provisioning** and placed on the box before it ships.

### Device lifecycle (why `/device/register` looked odd)

`POST /api/device/register` is not an app endpoint — it's step 1 of a
**warehouse workflow** performed by an operator:

```
RECEIVED ──▶ STRIPPED ──▶ PROVISIONED ──▶ READY_TO_SHIP
   ▲             ▲              ▲
 register     factory       token MINTED here
 (operator)   cleanup       (device Bearer)
```

1. `POST /device/register` (operator cookie) — box arrives at the warehouse,
   logged by `serial_number` (+ optional `mac_wifi`/`mac_eth`/`android_id`/
   `os_version`). 409 if the MAC already exists. Status: `RECEIVED`.
2. `POST /device/{id}/status` (operator) — advances the status **one step at a
   time**. Reaching `PROVISIONED`/`READY_TO_SHIP` mints the device Bearer token.
3. `POST /api/subscriber` + `POST /subscriber/{id}/assign-device` — a customer
   is created and the box (must be `READY_TO_SHIP`) is assigned to them.
4. The box ships. From then on it only ever calls **device-facing** endpoints
   with its Bearer token.

### Runtime (what the shipped box calls)

- `POST /api/device/checkin` (Bearer) — **the heartbeat**. Box reports
  `{android_id, mac_address, installed_app_version, device_model, os_version}`;
  server replies with latest app version + APK URL, DRM token, channel-list
  URL, and **pending MDM commands**. First check-in activates the subscriber
  (`PENDING_ACTIVATION → ACTIVE`). Errors: 401 bad token, 409
  `DEVICE_UNASSIGNED`, 403 suspended/cancelled.
- `GET /api/device/{id}/update` — **public**, lightweight update check
  (verified 2026-07-22: unknown id → 404 `NOT_FOUND` with no auth).
- `GET /api/device/{id}/config` — **public**, runtime config JSON.
- `GET /api/app-version/{id}/apk` — APK download (operator **or** Bearer);
  response carries `x-apk-sha256` for verification.
- `POST /api/command/{id}/ack` — ack an executed MDM command
  (`{status: ACKED|FAILED, result?}`). Unacked commands are redelivered on the
  next check-in. MDM command set: `UPDATE_APP, PUSH_CONFIG, REBOOT, GET_LOGS,
  KIOSK_LOCK, KIOSK_UNLOCK, WIPE` — mapping ~1:1 onto our StbBridge natives.
- Command delivery is check-in polling, or FCM in production — but FCM needs
  Google Play Services, which X88-class AOSP boxes don't reliably have (and
  our kiosk maintenance removes the Play Store), so **polling is the
  dependable channel** for this fleet.

## What the app did wrong (pre-2026-07-22) and the migration

The first integration was built by reading the endpoints, not the lifecycle,
so the app impersonated an **operator** instead of acting as a **device**:

1. It embedded operator credentials in the APK and logged in as the operator —
   APK-extractable creds that grant tenant-wide power (up to fleet `WIPE`).
2. It called the warehouse-only `/device/register` on boot. The
   409 MAC-collision bug we chased in debug was actually the API correctly
   rejecting improper self-registration of an unprovisioned device.
3. It sent the operator cookie to `/device/{id}/update`, which needs no auth.
4. It never called `/device/checkin`, the endpoint the design centres on.

### Migration status

| Step | Status |
|---|---|
| Update check made cookie-less (public endpoint) | ✅ 2026-07-22 |
| Check-in + command-ack plumbing, Bearer-token-gated (`stb_device_token`) | ✅ 2026-07-22 (dormant until boxes hold tokens) |
| Device-token provisioning story (how a box receives its Bearer token; also fixes 409/wipe recovery) | ⏳ needs backend/warehouse decision |
| Execute MDM commands via StbBridge + ack | ⏳ after tokens exist (currently commands are logged only, never acked → redelivered) |
| Remove embedded operator creds + self-registration | ⏳ last, once provisioning replaces them |

Check-in response field names are **unverified** (the OpenAPI spec omits
response schemas): `DeviceCheckinModel` parses the documented fields
defensively and keeps the raw JSON — confirm against a real provisioned
device and tighten.

## MDM command plan (decided 2026-07-22, parked until enrollment)

Delivery is **check-in polling**, not FCM (X88-class boxes lack reliable GMS
and kiosk maintenance removes the Play Store). Policy: poll on boot + every
**3 min ± jitter** (agreed range 1–5 min), back off to ~15 min after repeated
failures, reset on success; make the interval server-tunable via
`/device/{id}/config` later. Ack ordering: commands that kill the app
(`REBOOT`, `UPDATE_APP`, `WIPE`) are **acked before executing** — otherwise
the unacked command redelivers on the next check-in and the box loops.
Everything else executes first, then acks `ACKED`/`FAILED` + result.

Coverage vs existing natives (`StbSystemService` + `UpdateInstaller`):

| Command | Support | Via |
|---|---|---|
| `REBOOT` | ✅ ready | `StbSystemService.reboot()` (root) |
| `UPDATE_APP` | ✅ ready | `UpdateInstaller` download → SHA-256 verify → install; APK URL from payload or public `/update` |
| `PUSH_CONFIG` | ✅ easy | refetch public `/config`, apply app-side |
| `KIOSK_LOCK` / `KIOSK_UNLOCK` | ✅ Flutter-side | full-screen suspension/lock UI in the app (box is already kiosk-locked to our app, so a Flutter barrier is effectively enforceable); native lock-task hardening optional later |
| `GET_LOGS` | ✅ via ack | **no log-upload endpoint exists in the API** (`/api/audit` is the operator audit trail, not device logs) — deliver logs in the ack's `result` field (size-capped); a dedicated upload URL only if backend adds one |
| `WIPE` | ⛔ out of scope (2026-07-22) | ack `FAILED: unsupported` |

Note on unpaid users: KIOSK_LOCK is not the primary tool for that — check-in
already returns **403 when the subscriber is suspended/cancelled**, so the
natural design is: 403 → Flutter lock screen ("account suspended"), restored
automatically when check-in succeeds again. KIOSK_LOCK stays as the manual
operator override. Both depend on check-in, i.e. on enrollment.

Command **payload schemas are not in the spec** (only `{type: ...}` is shown);
per-type payload shapes (UPDATE_APP apk ref, PUSH_CONFIG body) must be
confirmed with the backend team — needed before building the executor, but
not blocking anything now.
