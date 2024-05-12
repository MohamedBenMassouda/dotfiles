#!/bin/bash

# Get tmux session names
if !tmux ls > /dev/null 2>&1; then
    echo "No tmux sessions found"
    exit 0
fi

mapfile -t list < <(tmux ls | awk '{print $1}')

# Select a session using Rofi
selected_session=$(printf '%s\n' "${list[@]}" | rofi -dmenu -p "Select a session: ")

# Attach to the selected session
if [ -n "$selected_session" ]; then
    kitty tmux attach-session -t "$selected_session"
fi
