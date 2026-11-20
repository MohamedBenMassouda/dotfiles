#!/usr/bin/env bash
# Says which app systemd-oomd closed when memory ran out (system/oomd/), so an app that
# vanishes isn't a mystery. Started at login (configs/Startup_Apps.lua); one copy only.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/oom-watch.lock"
flock -n 9 || exit 0

journalctl -f -n 0 -o cat -u systemd-oomd | while read -r line; do
  [[ $line == Killed* ]] || continue
  # uwsm names apps "app-Hyprland-kitty-0a660084.scope", Flatpaks "app-flatpak-<id>-1234.scope",
  # autostart "app-blueman@autostart.service", with "-" escaped as \x2d → just the app's name
  unit=$(grep -o -E 'app-[^/ ]+\.(scope|service)' <<< "$line" | tail -1)
  app=$(sed -E 's/^app-//; s/^Hyprland-//; s/^flatpak-//; s/@.*//; s/-[0-9a-f]+\.scope$//; s/\.(scope|service)$//; s/\\x2d/-/g' <<< "$unit")
  qs ipc call osd rich memory "Memory ran out" "Closed ${app:-an app} to keep the desktop running" \
    '{"sticky": true}' >/dev/null 2>&1 || notify-send -u critical "Memory ran out" "Closed ${app:-an app}"
done
