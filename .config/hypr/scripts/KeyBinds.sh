#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Searchable keybinds using rofi, read live from Hyprland (descriptions set in the Lua config)

pkill yad || true
pidof rofi >/dev/null && pkill rofi


hyprctl binds -j | jq -r '
  .[] | select(.description != "")
  | [ (if .modmask % 128 >= 64 then "SUPER" else empty end),
      (if .modmask % 8 >= 4 then "CTRL" else empty end),
      (if .modmask % 16 >= 8 then "ALT" else empty end),
      (if .modmask % 2 >= 1 then "SHIFT" else empty end),
      (if .key == "" and .keycode >= 10 and .keycode <= 19 then ((.keycode - 9) % 10 | tostring) else .key end)
    ] as $k
  | "\($k | join("+")) ➜ \(.description)"' |
  awk '!seen[$0]++' |
  rofi -dmenu -i -p "Keybinds"
