#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For disabling touchpad.
# Edit the touchpad hl.device name in ~/.config/hypr/configs/Laptops.lua according to your system
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

set -euo pipefail

notif="$HOME/.config/hypr/assets/images/ja.png"
laptops_conf="$HOME/.config/hypr/configs/Laptops.lua"

touchpad_device="${TOUCHPAD_DEVICE:-}"
if [[ -z "$touchpad_device" && -f "$laptops_conf" ]]; then
    touchpad_device="$(
        grep -oP 'name\s*=\s*"\K[^"]*touchpad[^"]*' "$laptops_conf" | head -1
    )"
fi

if [[ -z "$touchpad_device" ]]; then
    notify-send -u low -i "$notif" " Touchpad" " Device name not set (check configs/Laptops.lua)"
    exit 1
fi

status_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.status"

enable_touchpad() {
    printf "true" >"$status_file"
    qs ipc call osd toast touchpad "Touchpad on" "" >/dev/null 2>&1 || notify-send -u low "Touchpad on"
    hyprctl eval "hl.device({ name = \"$touchpad_device\", enabled = true })"
}

disable_touchpad() {
    printf "false" >"$status_file"
    qs ipc call osd toast touchpad-off "Touchpad off" "Fn key again to turn it back on" >/dev/null 2>&1 || notify-send -u low "Touchpad off"
    hyprctl eval "hl.device({ name = \"$touchpad_device\", enabled = false })"
}

current_state="false"
if [[ -f "$status_file" ]]; then
    current_state="$(<"$status_file")"
fi

if [[ "$current_state" == "true" ]]; then
    disable_touchpad
else
    enable_touchpad
fi
