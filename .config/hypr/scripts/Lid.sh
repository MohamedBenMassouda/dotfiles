#!/usr/bin/env bash
# Laptop lid with an external monitor plugged in (bound in configs/Laptops.lua).
# Without one, logind suspends on lid close as usual and this does nothing.
#   Lid.sh close   turn the laptop screen off, windows move to the other monitor
#   Lid.sh open    turn it back on (hyprctl reload re-applies monitors.lua)
laptop=$(hyprctl monitors all -j | jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)"))][0].name // empty')
[[ -n $laptop ]] || exit 0
toast() { qs ipc call osd toast "$@" >/dev/null 2>&1; }

case $1 in
  close)
    others=$(hyprctl monitors -j | jq -r --arg l "$laptop" '[.[] | select(.name != $l) | .name] | join(", ")')
    [[ -n $others ]] || exit 0
    hyprctl eval "hl.monitor({ output = \"$laptop\", disabled = true })" >/dev/null
    toast laptop "Lid closed" "Using $others only"
    ;;
  open)
    hyprctl monitors -j | jq -e --arg l "$laptop" 'any(.[]; .name == $l)' >/dev/null && exit 0
    hyprctl reload >/dev/null
    toast laptop-on "Lid open" "$laptop is back on"
    ;;
esac
