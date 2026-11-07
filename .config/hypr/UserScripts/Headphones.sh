#!/usr/bin/env bash
# Connect/disconnect the Sony WH-CH720N.
#   Headphones.sh auto   -> at login: keep trying for ~30s while bluetooth comes up
#   Headphones.sh        -> toggle (bound to SUPER+ALT+H)
MAC="00:A4:1C:9D:33:C8"
icon="$HOME/.config/swaync/images/ja.png"

connected() { bluetoothctl info "$MAC" | grep -q "Connected: yes"; }

if [[ "${1:-}" == auto ]]; then
  for _ in $(seq 10); do
    connected && exit 0
    bluetoothctl connect "$MAC" >/dev/null 2>&1 && exit 0
    sleep 3
  done
  exit 0
fi

if connected; then
  bluetoothctl disconnect "$MAC" >/dev/null   # Quickshell shows the flyout
else
  bluetoothctl power on >/dev/null
  if ! bluetoothctl connect "$MAC" >/dev/null; then
    notify-send -e -u low -i "$icon" " Headphones" "Not found - are they on?"
  fi
fi
