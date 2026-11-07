#!/usr/bin/env bash
# Jump to any open window, on any workspace or monitor (SUPER+X).
# Most recently used first; the previous window is preselected, like alt-tab.
set -euo pipefail

source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
menu_toggle windows || exit 0

clients=$(hyprctl clients -j | jq 'map(select(.mapped)) | sort_by(.focusHistoryID)')
mapfile -t addrs < <(jq -r '.[].address' <<<"$clients")
[[ ${#addrs[@]} -gt 0 ]] || exit 0

sel=$([[ ${#addrs[@]} -gt 1 ]] && echo 1 || echo 0)
choice=$(jq -j '.[] | "\(.class) · \(.title | gsub("\n"; " ")) · \(.workspace.name)\u0000icon\u001f\(.class | ascii_downcase)\n"' <<<"$clients" |
  rofi -dmenu -i -p "Windows" -show-icons -format i -selected-row "$sel") || exit 0
[[ -n "$choice" ]] || exit 0

hyprctl dispatch "hl.dsp.focus({ window = 'address:${addrs[$choice]}' })" >/dev/null
