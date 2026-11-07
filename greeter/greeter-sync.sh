#!/usr/bin/env bash
# Copy what the login screen needs into /etc/greetd/greeter: its own files from
# the dotfiles, your monitor layout, theme colours and current wallpaper.
# Runs as root (greeter-sync.service, started when those files change), but
# reads everything as you, so it can only copy files you can read anyway.
#   greeter-sync <user>
set -euo pipefail
user=${1:?usage: greeter-sync <user>}
home=$(getent passwd "$user" | cut -d: -f6)
dots=$(dirname "$(dirname "$(realpath "$home/.config/hypr")")")
dst=/etc/greetd/greeter

copy() {   # copy <source> <dest> <mode>: read as the user, write as root
  runuser -u "$user" -- cat "$1" > "$2.tmp"
  chmod "$3" "$2.tmp"
  mv -f "$2.tmp" "$2"
}

install -d -m 755 "$dst" "$dst/quickshell"
copy "$dots/greeter/hyprland.lua" "$dst/hyprland.lua" 644
copy "$dots/greeter/start-greeter.sh" "$dst/start-greeter.sh" 755
for f in "$dots"/greeter/quickshell/*.qml; do
  copy "$f" "$dst/quickshell/$(basename "$f")" 644
done
copy "$home/.config/hypr/monitors.lua" "$dst/monitors.lua" 644
copy "$home/.config/quickshell/Theme.qml" "$dst/quickshell/Theme.qml" 644
copy "$home/.config/quickshell/colors.json" "$dst/quickshell/colors.json" 644
copy "$home/.config/rofi/.current_wallpaper" "$dst/quickshell/wallpaper" 644
