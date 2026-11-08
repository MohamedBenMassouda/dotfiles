#!/usr/bin/env bash
# Buttons of the "runaway app" spider-sense flyout (Quickshell Osd.qml):
#   Runaway.sh show PID   focus the window that process belongs to
#   Runaway.sh stop PID   ask it to quit (SIGTERM; a Firefox tab process just
#                         reloads as "tab crashed", the rest of Firefox stays)
pid=$2
[[ $pid =~ ^[0-9]+$ ]] || exit 1
case $1 in
  show)
    declare -A win
    while read -r p a; do win[$p]=$a; done < <(hyprctl clients -j | jq -r '.[] | "\(.pid) \(.address)"')
    while [[ -n $pid && $pid -gt 1 && -z ${win[$pid]:-} ]]; do pid=$(ps -o ppid= -p "$pid" | tr -d ' '); done
    [[ -n ${win[$pid]:-} ]] && hyprctl dispatch "hl.dsp.focus({ window = \"address:${win[$pid]}\" })" >/dev/null
    ;;
  stop) kill -TERM "$pid" ;;
esac
