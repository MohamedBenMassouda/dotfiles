#!/usr/bin/env bash
# A tmux window watched with prefix+M stayed quiet for 2 minutes (a long job finished or got
# stuck): say so on the desktop. Called by the alert-silence hook in ~/.tmux.conf.
qs ipc call osd toast done "tmux: $2 went quiet" "Session $1 · no output for 2 min" >/dev/null 2>&1 \
  || notify-send "tmux: $2 went quiet" "Session $1 · no output for 2 min"
