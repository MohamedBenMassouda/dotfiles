#!/usr/bin/env bash
# Unsticks Bluetooth. The Realtek chip (RTL8822CU) sometimes gets stuck, often after heavy
# 2.4 GHz traffic (the controller's dongle right next to it): every connection then fails
# with "Function not implemented (38)" in bluetoothd's log until Bluetooth is switched off
# and on. This watches that log, does the off/on, reconnects what was connected (plus the
# device that failed) and says so in a flyout. At most once every 2 minutes.
# Started at login (configs/Startup_Apps.lua); one copy only (the lock file).
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/bt-watch.lock"
flock -n 9 || exit 0

STUCK="Function not implemented (38)"
COOLDOWN=120
last=0

toast() { qs ipc call osd toast bluetooth "$1" "$2" >/dev/null 2>&1 || notify-send -e -u low "$1" "$2"; }

journalctl -f -n 0 -o cat -u bluetooth | while read -r line; do
  [[ $line == *"$STUCK"* ]] || continue
  now=$(date +%s)
  (( now - last < COOLDOWN )) && continue
  last=$now

  failed=$(grep -o -E '([0-9A-F]{2}:){5}[0-9A-F]{2}' <<< "$line" | head -1)
  mapfile -t devices < <({ bluetoothctl devices Connected | awk '{print $2}'; echo "$failed"; } | grep . | sort -u)
  toast "Bluetooth got stuck" "Restarting it and reconnecting your devices"
  bluetoothctl power off >/dev/null
  sleep 2
  bluetoothctl power on >/dev/null
  sleep 3
  back=()
  for mac in "${devices[@]}"; do
    timeout 20 bluetoothctl connect "$mac" >/dev/null 2>&1 \
      && back+=("$(bluetoothctl info "$mac" | sed -n 's/^\s*Name: //p')")
  done
  if (( ${#back[@]} )); then
    toast "Bluetooth is back" "Reconnected: $(IFS=,; echo "${back[*]}" | sed 's/,/, /g')"
  else
    toast "Bluetooth restarted" "Reconnect your device from quick settings"
  fi
done
