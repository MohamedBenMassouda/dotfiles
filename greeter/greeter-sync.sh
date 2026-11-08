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
# the theme pack's greeting line (empty with no pack); the greeter shows it under the date
pack=$(runuser -u "$user" -- cat "$home/.local/state/desktop-pack" 2>/dev/null || true)
pack=${pack:-spiderman}
json="$home/.config/quickshell/packs/$pack/pack.json"
if [[ $pack != none ]] && runuser -u "$user" -- test -f "$json"; then
  runuser -u "$user" -- cat "$json" |
    jq --arg u "$user" --arg h "$(cat /etc/hostname)" '{text: ((.greeting // "") | gsub("%u"; $u) | gsub("%h"; $h)), color: (.color // "")}'
else
  echo '{}'
fi > "$dst/greeting.json"
chmod 644 "$dst/greeting.json"
rm -f "$dst/spidey-off" "$dst/greeting" "$dst/quickshell/Mask.qml"
