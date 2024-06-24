#!/usr/bin/env bash

# Directory to search for project directories
PROJECT_DIR="/mnt/AA4C6EDE4C6EA4B3/Programming"
CACHE_FILE="$HOME/.cache/sessionizer"

if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Find directories and store the result
    result=$(find "$PROJECT_DIR" -mindepth 1 -maxdepth 2 -type d)

    # Exit if no directories are found
    if [[ -z $result ]]; then
        exit 0
    fi
    # Ensure cache directory exists
    mkdir -p "$(dirname "$CACHE_FILE")"

    # Update cache file if it's empty or contents have changed
    if [[ ! -s $CACHE_FILE ]] || [[ "$result" != "$(cat "$CACHE_FILE")" ]]; then
        echo "Updating cache file..."
        echo "$result" > "$CACHE_FILE"
    fi

    # Use fzf to select a directory from the cache
    selected=$(bat "$CACHE_FILE" | fzf)
fi

# Exit if no selection is made
if [[ -z $selected ]]; then
    exit 0
fi

# Normalize the selected directory name for TMUX session name
selected_name=$(basename "$selected" | tr . _)

# Check if TMUX is running
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    # Start a new TMUX session if TMUX is not already running
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

# Create a new TMUX session if it doesn't already exist
if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

# Attach to the existing or newly created TMUX session
tmux attach-session -t "$selected_name"

