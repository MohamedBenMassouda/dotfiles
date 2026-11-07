#!/usr/bin/env bash
# Toggle behaviour for rofi menus (source it, don't run it).
#   menu_toggle <name> || exit 0
# Put it near the top of a menu script, before rofi starts:
#   - this menu already open  -> closes it, returns 1 (the script exits)
#   - another menu open        -> closes that one, returns 0 (this one opens)
#   - nothing open             -> returns 0
# The open menu is remembered as "<name> <pid of its script>" in $XDG_RUNTIME_DIR.

menu_toggle() {
  local state="${XDG_RUNTIME_DIR:-/tmp}/rofi-menu" open="" pid=""
  if pidof -q rofi; then
    read -r open pid < "$state" 2>/dev/null || true
    pkill -x rofi
    if [[ "$open" == "$1" ]] && kill -0 "${pid:-0}" 2>/dev/null; then
      return 1
    fi
  fi
  printf '%s %s\n' "$1" "$$" > "$state"
}
