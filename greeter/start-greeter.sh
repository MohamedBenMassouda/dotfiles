#!/bin/sh
# greetd runs this as the "greeter" user (/etc/greetd/config.toml).
# Starts the graphical login screen (Hyprland + Quickshell). A normal login ends
# it with exit code 0; if it crashes or can't start, show a text login instead
# so you're never stuck at a black screen.
Hyprland -c /etc/greetd/greeter/hyprland.lua >/tmp/greeter-hyprland.log 2>&1 && exit 0
exec agreety --cmd "uwsm start -e -D Hyprland hyprland.desktop"
