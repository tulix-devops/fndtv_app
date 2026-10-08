#!/usr/bin/env bash
#
# Provision a set-top box so FNDTV is the launcher and the preinstalled apps
# are gone — over adb, WITHOUT root and WITHOUT a factory reset.
#
# WHY THIS EXISTS
#
# Everything here is work the app itself cannot do. An installed app runs as
# uid 10xxx and is refused `pm uninstall`, `pm disable-user`, the HOME role and
# `dpm`. StbBridge tries to reach past that with `su`, which only works on a box
# whose superuser layer grants root to our package — and on several boxes in the
# field it does not. `adb shell` runs as uid 2000 (`shell`), which holds those
# privileges outright. Same operations, a privilege level we can actually get.
#
# WHAT IT DOES
#   1. finds every app that can answer the HOME intent (not a hardcoded list)
#   2. disables them — reversible, and enough to stop them resolving HOME
#   3. hands FNDTV the HOME role, both the modern and legacy way
#   4. removes the preinstalled apps for user 0
#   5. tries device owner (only possible before setup completes)
#   6. VERIFIES, and prints what actually holds
#
# WHAT IT DOES NOT DO
#   - factory reset anything
#   - touch /system, or need an unlocked bootloader
#   - permanently destroy apps: `pm uninstall --user 0` removes for this user
#     only, the APK stays on /system, and a factory reset restores everything
#
# UNDO
#   pm enable <pkg>                      # re-enable a disabled launcher
#   cmd package install-existing <pkg>   # restore an uninstalled system app
#
# USAGE
#   ./scripts/provision_box.sh                 # first device adb sees
#   ./scripts/provision_box.sh 192.168.1.42    # a box over adb-tcp
#   DRY_RUN=1 ./scripts/provision_box.sh       # print, change nothing
#   TZ=Europe/Paris ./scripts/provision_box.sh # also force the timezone (needs adb root)
#
# NOTE ON `adb root`
#
# The script tries `adb root` and reports whether it took. It is NOT required —
# everything above works as the plain shell user. But a box that allows it
# (userdebug / ro.debuggable=1, common on this hardware) opens the one option
# that a FACTORY RESET CANNOT UNDO: installing FNDTV into /system/priv-app as a
# privileged app, and deleting the stock launcher from the image. That also
# makes Build.getSerial() and the Wi-Fi MAC return real values, which is why the
# fleet currently falls back to Build.ID for both. It is a heavier, riskier
# operation than anything in this script — prove it on one box first — so it is
# deliberately NOT automated here.

set -uo pipefail

PKG="com.fndtv.videoplayer"
HOME_ACTIVITY="$PKG/$PKG.MainActivity"
ADMIN="$PKG/.MyDeviceAdminReceiver"

# Never disable or remove these, whatever they declare. com.android.settings
# hosts FallbackHome — the activity the framework shows when no launcher
# resolves. Disable it on a box with no other launcher and there is nothing
# left to display at all.
PROTECTED="android com.android.systemui com.android.settings com.android.tv.settings com.android.provision $PKG"

# Preinstalled apps to remove. Competing launchers are NOT listed — they are
# discovered at run time, because the launcher that steals a box is the one
# nobody thought to add to a list.
BLOAT="
com.google.android.youtube.tv
com.google.android.youtube
com.google.android.apps.youtube.music
com.google.android.videos
com.netflix.mediaclient
com.amazon.amazonvideo.livingroom
com.smartbox.launcher
com.android.vending
com.google.android.katniss
"

TARGET="${1:-}"
DRY_RUN="${DRY_RUN:-0}"

if [ -n "$TARGET" ]; then
  case "$TARGET" in
    *.*.*.*) adb connect "$TARGET:5555" >/dev/null 2>&1 || true
             ADB="adb -s $TARGET:5555" ;;
    *)       ADB="adb -s $TARGET" ;;
  esac
else
  ADB="adb"
fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; }
info() { printf '  · %s\n' "$*"; }

# Runs a command on the box and returns its output. In dry-run it returns the
# DRYRUN sentinel instead, which every caller reports as "would change" —
# printing here would be captured by `out=$(sh_ ...)` and then misread as the
# command's own output.
sh_() {
  if [ "$DRY_RUN" = "1" ]; then
    printf 'DRYRUN %s' "$*"
    return 0
  fi
  $ADB shell "$@" 2>&1
}

is_protected() {
  case " $PROTECTED " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# ── preflight ───────────────────────────────────────────────────────────────
say ""
say "FNDTV box provisioning"
say "══════════════════════"

if ! $ADB get-state >/dev/null 2>&1; then
  bad "no device — check the cable, or 'adb connect <ip>:5555'"
  exit 1
fi

MODEL=$($ADB shell getprop ro.product.model 2>/dev/null | tr -d '\r')
RELEASE=$($ADB shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
SDK=$($ADB shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
BUILDTYPE=$($ADB shell getprop ro.build.type 2>/dev/null | tr -d '\r')
DEBUGGABLE=$($ADB shell getprop ro.debuggable 2>/dev/null | tr -d '\r')
say ""
info "box:     ${MODEL:-unknown}"
info "android: ${RELEASE:-?} (API ${SDK:-?})"
info "build:   ${BUILDTYPE:-?} (ro.debuggable=${DEBUGGABLE:-?})"
[ "$DRY_RUN" = "1" ] && info "DRY RUN — nothing will be changed"

# ── try to raise the adb daemon to root ─────────────────────────────────────
#
# `adb root` restarts adbd as uid 0, after which every shell command below runs
# as root — a DIFFERENT mechanism from the in-app `su`, and one that needs no
# grant from any superuser layer. It only works on a box whose build permits it
# (userdebug / ro.debuggable=1), which these boxes often are.
#
# Not required: everything this script does works as the plain `shell` user
# (uid 2000). Root only adds the few things shell cannot do, and is reported so
# you know which box you are dealing with.
ADB_ROOT=no
if [ "$DRY_RUN" != "1" ]; then
  root_out=$($ADB root 2>&1 | tr -d '\r')
  case "$root_out" in
    *"cannot run as root"*|*"not permitted"*)
      info "adb root: refused (production build) — continuing as shell" ;;
    *)
      # adbd restarts, so the connection drops for a moment.
      sleep 2
      $ADB wait-for-device >/dev/null 2>&1
      if [ "$($ADB shell id -u 2>/dev/null | tr -d '\r')" = "0" ]; then
        ADB_ROOT=yes
        ok "adb root: GRANTED — shell commands run as root on this box"
      else
        info "adb root: no effect — continuing as shell"
      fi ;;
  esac
fi

if ! $ADB shell pm list packages 2>/dev/null | tr -d '\r' | grep -qx "package:$PKG"; then
  say ""
  bad "$PKG is not installed — install the APK first:"
  say "      adb install -r build/app/outputs/flutter-apk/app-stb-release.apk"
  exit 1
fi

# ── 1. find the competition ─────────────────────────────────────────────────
say ""
say "1. Launchers that can take HOME"

CANDIDATES=$($ADB shell "cmd package query-activities -a android.intent.action.MAIN \
  -c android.intent.category.HOME --user 0" 2>/dev/null \
  | tr -d '\r' | grep -oE 'packageName=[A-Za-z0-9_.]+' | cut -d= -f2 | sort -u)

COMPETITORS=""
for p in $CANDIDATES; do
  is_protected "$p" && continue
  COMPETITORS="$COMPETITORS $p"
done

if [ -z "${COMPETITORS// /}" ]; then
  ok "none besides FNDTV"
else
  for p in $COMPETITORS; do info "found: $p"; done
fi

# ── 2. disable them ─────────────────────────────────────────────────────────
# BEFORE pinning, never after: Android drops a preferred-activity record as soon
# as the set of matching activities changes, so disabling a launcher after
# setting HOME invalidates the setting you just made.
if [ -n "${COMPETITORS// /}" ]; then
  say ""
  say "2. Disabling them (reversible: pm enable <pkg>)"
  for p in $COMPETITORS; do
    out=$(sh_ "pm disable-user --user 0 $p")
    case "$out" in
      DRYRUN*) info "would disable $p" ;;
      *"new state: disabled"*) ok "$p" ;;
      *) bad "$p — $(printf '%s' "$out" | head -1)" ;;
    esac
  done
fi

# ── 3. hand HOME to FNDTV ───────────────────────────────────────────────────
say ""
say "3. Making FNDTV the home app"
# Modern Android decides the launcher through RoleManager; older boxes through
# the preferred-activity table. Do both and let the verification below say which
# one took.
sh_ "cmd role add-role-holder android.app.role.HOME $PKG" >/dev/null 2>&1
sh_ "cmd package set-home-activity $HOME_ACTIVITY" >/dev/null 2>&1

# ── 4. remove the preinstalled apps ─────────────────────────────────────────
say ""
say "4. Removing preinstalled apps"
INSTALLED=$($ADB shell "pm list packages --user 0" 2>/dev/null | tr -d '\r')
for p in $BLOAT; do
  is_protected "$p" && continue
  printf '%s' "$INSTALLED" | grep -qx "package:$p" || { info "$p (not present)"; continue; }
  out=$(sh_ "pm uninstall -k --user 0 $p")
  case "$out" in
    DRYRUN*) info "would remove $p" ;;
    *Success*) ok "$p removed" ;;
    *)
      # Firmware refuses to uninstall some packages; disabling cannot be refused.
      out2=$(sh_ "pm disable-user --user 0 $p")
      case "$out2" in
        *"new state: disabled"*) ok "$p disabled (uninstall refused)" ;;
        *) bad "$p — $(printf '%s' "$out" | head -1)" ;;
      esac ;;
  esac
done

# ── 5. device owner (best effort) ───────────────────────────────────────────
say ""
say "5. Device owner"
# The only permanent lock: it pins HOME through the framework so the user cannot
# change it, and lets the app hide apps and install updates silently with no
# root. Refused on any box that has finished setup — the message says which.
if $ADB shell dumpsys device_policy 2>/dev/null | tr -d '\r' | grep -q "Device Owner:"; then
  info "already set (see the summary below)"
else
  out=$(sh_ "dpm set-device-owner $ADMIN")
  case "$out" in
    DRYRUN*) info "would attempt device owner" ;;
    *Success*) ok "granted — HOME is now locked at the framework level" ;;
    *) info "not granted: $(printf '%s' "$out" | tr -d '\r' | grep -v '^$' | head -2 | tr '\n' ' ')"
       info "expected on a box that has completed setup; the steps above still stand" ;;
  esac
fi

# ── 6. clock ────────────────────────────────────────────────────────────────
say ""
say "6. Clock"
sh_ "settings put global auto_time 1" >/dev/null 2>&1
sh_ "settings put global auto_time_zone 1" >/dev/null 2>&1
# Only root can write the timezone property. Pass TZ=Europe/Paris to set it
# explicitly on a box whose automatic lookup is not working — this is the EPG
# problem, since every schedule time is rendered through the system zone.
if [ -n "${TZ:-}" ] && [ "$ADB_ROOT" = "yes" ]; then
  sh_ "setprop persist.sys.timezone $TZ" >/dev/null 2>&1
  sh_ "am broadcast -a android.intent.action.TIMEZONE_CHANGED --es time-zone $TZ" >/dev/null 2>&1
  ok "timezone set to $TZ"
elif [ -n "${TZ:-}" ]; then
  info "TZ=$TZ requested but adb root is not available — skipped"
fi
if [ "$DRY_RUN" = "1" ]; then
  info "would enable automatic date/time + timezone"
else
  ok "automatic date/time + timezone enabled"
fi

# ── 7. verify ───────────────────────────────────────────────────────────────
say ""
say "7. Result"
if [ "$DRY_RUN" = "1" ]; then
  info "dry run — nothing was changed"
  exit 0
fi

HOME_NOW=$($ADB shell "cmd package resolve-activity -a android.intent.action.MAIN \
  -c android.intent.category.HOME --user 0" 2>/dev/null \
  | tr -d '\r' | grep -oE 'packageName=[A-Za-z0-9_.]+' | head -1 | cut -d= -f2)

LEFT=$($ADB shell "cmd package query-activities -a android.intent.action.MAIN \
  -c android.intent.category.HOME --user 0" 2>/dev/null \
  | tr -d '\r' | grep -oE 'packageName=[A-Za-z0-9_.]+' | cut -d= -f2 | sort -u)

REMAIN=""
for p in $LEFT; do
  is_protected "$p" && continue
  REMAIN="$REMAIN $p"
done

DO_STATE=no
$ADB shell dumpsys device_policy 2>/dev/null | tr -d '\r' | grep -q "Device Owner:" && DO_STATE=yes

say ""
info "home app now:     ${HOME_NOW:-unknown}"
info "device owner:     $DO_STATE"
info "other launchers:  ${REMAIN:-none}"
info "adb root:         $ADB_ROOT"
say ""
# Worth knowing per box: an `adb root` box can also take FNDTV into /system as a
# privileged app, which is the only change here that a factory reset does NOT
# undo — and which additionally fixes the serial and MAC reads. See the notes at
# the top of this file.
if [ "$ADB_ROOT" = "yes" ]; then
  info "this box allows adb root — a /system install is possible on it"
fi

if [ "$HOME_NOW" = "$PKG" ] && { [ "$DO_STATE" = "yes" ] || [ -z "${REMAIN// /}" ]; }; then
  ok "DONE — FNDTV owns HOME and nothing can take it back."
  say "     Reboot the box to confirm it comes up on FNDTV."
  exit 0
elif [ "$HOME_NOW" = "$PKG" ]; then
  bad "FNDTV owns HOME, but these can still take it:${REMAIN}"
  say "     It may revert on a future reboot. Send this output on."
  exit 2
else
  bad "FNDTV did NOT take HOME (it is ${HOME_NOW:-unknown})."
  say "     Send this whole output on — the failing step is above."
  exit 3
fi
