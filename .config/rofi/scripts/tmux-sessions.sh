#!/bin/bash

# Get tmux session names
if !tmux ls > /dev/null 2>&1; then
    notify-send "No tmux sessions found"
    exit 0
fi

mapfile -t list < <(tmux ls | awk '{print $1}')

if [ ${#list[@]} -eq 0 ]; then
    notify-send -u normal "No tmux sessions found"
    exit 0
fi

# Select a session using Rofi
selected_session=$(printf '%s\n' "${list[@]}" | rofi -dmenu -p "Select a session: ")

# Attach to the selected session
if [ -n "$selected_session" ]; then
    kitty tmux attach-session -t "$selected_session"
fi
