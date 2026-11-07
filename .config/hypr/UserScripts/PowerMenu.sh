#!/usr/bin/env bash
# Power applet (CTRL+ALT+P): lock, suspend, log out, restart, shut down.
# Log out / restart / shut down ask first, and close apps gracefully via hyprshutdown.
source "$(dirname "$(realpath "$0")")/applet.sh"
menu_toggle power || exit 0

choice=$(applet $'\U000F0150'" Up $(uptime -p | sed 's/^up //')" \
  $'\U000F033E|Lock' \
  $'\U000F0904|Suspend' \
  $'\U000F0343|Log out' \
  $'\U000F0709|Restart' \
  $'\U000F0425|Shut down') || exit 0

case "$choice" in
  0) "$HOME/.config/hypr/scripts/LockScreen.sh" ;;
  1) systemctl suspend ;;
  2) confirm "Log out?" && hyprshutdown -t 'Logging out...' ;;
  3) confirm "Restart?" && hyprshutdown -t 'Restarting...' --post-cmd 'systemctl reboot' ;;
  4) confirm "Shut down?" && hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff' ;;
esac
