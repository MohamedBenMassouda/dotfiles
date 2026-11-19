#!/usr/bin/env bash
# At login: a warning flyout if the weekly disk health check (system/disk-health, run as
# root) found a drive reporting trouble, so there's time to copy files off before it fails.
# Silent when everything is fine or the check isn't installed yet.
status=/var/lib/disk-health/status
[[ -r $status ]] || exit 0
sleep 20   # after the bar has started
grep ' PROBLEM ' "$status" | while read -r _disk _ details; do
  qs ipc call osd rich disk "Disk health warning" "$details · back up what matters on it" \
    '{"sticky": true}' >/dev/null 2>&1 || notify-send -u critical "Disk health warning" "$details"
done
