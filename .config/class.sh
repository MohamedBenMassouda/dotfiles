#!/bin/bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    base_path="/mnt/7C2885E92885A2AE/Class"
    results=$(find "$base_path" -mindepth 1 -maxdepth 2 -type d)
    results="$base_path"$'\n'"$results"

    if [[ -z $results ]]; then
        exit 0
    fi 

    selected=$(echo -e "$results" | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    # zellij a -c $selected_name -- -d $selected
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

# tmux switch-client -t $selected_name
tmux attach-session -t $selected_name
