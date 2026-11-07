#!/bin/sh
# greetd runs this as the "greeter" user (/etc/greetd/config.toml).
# Starts the graphical login screen (Hyprland + Quickshell). A normal login ends
# it with exit code 0; if it crashes or can't start, show a text login instead
# so you're never stuck at a black screen.

# the greeter account has no home folder: give it a throwaway one for caches/settings
export HOME=/tmp/greeter
export XDG_CACHE_HOME=$HOME/.cache XDG_CONFIG_HOME=$HOME/.config XDG_STATE_HOME=$HOME/.local/state XDG_DATA_HOME=$HOME/.local/share
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME"

start-hyprland -- -c /etc/greetd/greeter/hyprland.lua >/tmp/greeter-hyprland.log 2>&1 && exit 0
exec agreety --cmd "uwsm start -e -D Hyprland hyprland.desktop"
