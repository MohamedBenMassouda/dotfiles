#!/usr/bin/env bash
# Pick an audio output or input with rofi; it becomes the default (SUPER+ALT+A).
# Playing streams follow the new default (WirePlumber moves them).
# Built-in card entries name the port in use, e.g. "Headphones · Built-in Audio"
# when something is plugged in the jack.
set -euo pipefail

source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
menu_toggle audio || exit 0

def_sink=$(pactl get-default-sink)
def_src=$(pactl get-default-source)

kinds=() names=() labels=() icons=() active=()
while IFS=$'\t' read -r name desc; do
  [[ "$name" == "$def_sink" ]] && active+=("${#names[@]}")
  kinds+=(sink) names+=("$name") labels+=("Output: $desc") icons+=(audio-speakers)
done < <(pactl -f json list sinks | jq -r '.[] | . as $p | "\(.name)\t\((.ports[]? | select(.name == $p.active_port) | .description + " · ") // "")\(.description | sub(" Analog Stereo$"; ""))"')
while IFS=$'\t' read -r name desc; do
  [[ "$name" == "$def_src" ]] && active+=("${#names[@]}")
  kinds+=(source) names+=("$name") labels+=("Input: $desc") icons+=(audio-input-microphone)
done < <(pactl -f json list sources | jq -r '.[] | select(.name | endswith(".monitor") | not) | . as $p | "\(.name)\t\((.ports[]? | select(.name == $p.active_port) | .description + " · ") // "")\(.description | sub(" Analog Stereo$"; ""))"')

[[ ${#names[@]} -gt 0 ]] || exit 0

# the current output and input are highlighted
choice=$(for i in "${!labels[@]}"; do printf '%s\0icon\x1f%s\n' "${labels[$i]}" "${icons[$i]}"; done |
  rofi -dmenu -i -p "Audio" -show-icons -format i -a "$(IFS=,; echo "${active[*]}")") || exit 0
[[ -n "$choice" ]] || exit 0

pactl "set-default-${kinds[$choice]}" "${names[$choice]}"
notify-send -e -u low -h string:x-canonical-private-synchronous:audio-switch \
  -i "$HOME/.config/hypr/assets/images/ja.png" " Audio" "${labels[$choice]}"
