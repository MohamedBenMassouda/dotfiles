#!/usr/bin/env bash
# Lock the screen with the Quickshell lock (~/.config/quickshell/lock.qml).
# Falls back to hyprlock if the Quickshell lock doesn't confirm within 3 s
# (e.g. a QML error), so a broken lock file never leaves you unlocked.
# Run by hypridle's lock_cmd (loginctl lock-session / LockScreen.sh).
marker="$XDG_RUNTIME_DIR/qs-lock-active"
lockqml="$HOME/.config/quickshell/lock.qml"

pidof hyprlock >/dev/null && exit 0
[[ -e $marker ]] && pgrep -f "qs -p $lockqml" >/dev/null && exit 0   # already locked

rm -f "$marker"
qs -p "$lockqml" >/dev/null 2>&1 &
pid=$!
for _ in $(seq 30); do
  [[ -e $marker ]] && exit 0
  kill -0 "$pid" 2>/dev/null || break
  sleep 0.1
done
kill "$pid" 2>/dev/null
exec hyprlock
