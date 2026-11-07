#!/usr/bin/env bash
# Flyout when a long terminal command ends while you're looking at another window
# (called by the hook in ~/.zshrc for commands over 30 s).
#   CmdDone.sh <exit status> <seconds> <pid inside the terminal> <command>
# The "Show" button focuses that terminal window again.
status=$1 secs=$2 pid=$3 cmd=$4

# the terminal window: walk up from the pid until a Hyprland window owns it
declare -A win
while read -r p a; do win[$p]=$a; done < <(hyprctl clients -j | jq -r '.[] | "\(.pid) \(.address)"')
while [[ -n $pid && $pid -gt 1 && -z ${win[$pid]:-} ]]; do
  pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done
addr=${win[$pid]:-}

# still looking at it: nothing to tell
[[ -n $addr && $(hyprctl activewindow -j | jq -r .address) == "$addr" ]] && exit 0

(( secs >= 60 )) && took="$((secs / 60)) min $((secs % 60)) s" || took="$secs s"
short=${cmd:0:60}
if (( status == 0 )); then kind=done title="Done: $short"; sub="Took $took"
else kind=failed title="Failed: $short"; sub="Exit $status after $took"; fi

extra='{}'
[[ -n $addr ]] && extra=$(jq -nc --arg a "$addr" '{actions: [{label: "Show", glyph: 983437,
  cmd: ["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:\($a)\" })"]}]}')
qs ipc call osd rich "$kind" "$title" "$sub" "$extra" >/dev/null 2>&1 || notify-send "$title" "$sub"
