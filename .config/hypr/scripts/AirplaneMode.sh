#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Airplane Mode. Turning on or off all wifi using rfkill. 


# Check if any wireless device is blocked
wifi_blocked=$(rfkill list wifi | grep -o "Soft blocked: yes")

if [ -n "$wifi_blocked" ]; then
    rfkill unblock wifi
    qs ipc call osd toast airplane-off "Airplane mode off" "Wi-Fi back on" >/dev/null 2>&1 || notify-send -u low "Airplane mode off"
else
    rfkill block wifi
    qs ipc call osd toast airplane "Airplane mode on" "Wi-Fi off" >/dev/null 2>&1 || notify-send -u low "Airplane mode on"
fi
