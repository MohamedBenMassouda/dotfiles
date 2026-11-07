#!/usr/bin/env bash
# Open a project in kitty + tmux (SUPER+T).
# Running tmux sessions are listed first, then every project folder that
# sessionizer.sh knows about. Picking a project runs sessionizer.sh, so it
# creates or reuses the same tmux session you'd get from the terminal.
set -euo pipefail

source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
menu_toggle projects || exit 0

PROJECT_DIR="/mnt/Data/Programming"
CUSTOM_CACHE_FILE="$HOME/.cache/sessionizer_custom"
SESSIONIZER="$HOME/.config/sessionizer.sh"

targets=() labels=() icons=()
while read -r s; do
  [[ -n "$s" ]] || continue
  targets+=("session:$s") labels+=("$s") icons+=(utilities-terminal)
done < <(tmux ls -F '#S' 2>/dev/null || true)

while read -r dir; do
  [[ -n "$dir" && -d "$dir" ]] || continue
  targets+=("dir:$dir") labels+=("${dir#"$PROJECT_DIR"/}") icons+=(folder)
done < <({ find "$PROJECT_DIR" -mindepth 1 -maxdepth 2 -type d -not -name '.*' 2>/dev/null | sort
           [[ -f "$CUSTOM_CACHE_FILE" ]] && cat "$CUSTOM_CACHE_FILE"; } || true)

[[ ${#targets[@]} -gt 0 ]] || { notify-send -u low "Projects" "Nothing found in $PROJECT_DIR"; exit 0; }

choice=$(for i in "${!labels[@]}"; do printf '%s\0icon\x1f%s\n' "${labels[$i]}" "${icons[$i]}"; done |
  rofi -dmenu -i -p "Projects" -show-icons -format i) || exit 0
[[ -n "$choice" ]] || exit 0

target=${targets[$choice]}
case "$target" in
  session:*) setsid -f kitty -e tmux attach-session -t "${target#session:}" ;;
  dir:*)     setsid -f kitty -e "$SESSIONIZER" "${target#dir:}" ;;
esac
