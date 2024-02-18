#!/bin/bash

base_directory="/mnt/AA4C6EDE4C6EA4B3/Programming"
selected_directory=$(ls -a $base_directory | fzf)

if [ -n "$selected_directory" ]; then
    # Add an option to select the current directory
    if [ $selected_directory == "." ]; then
        cd "$base_directory"
        exec tmux new-session -s $selected_directory 
    else
        if [ $selected_directory == "C#" ]; then
            selected_directory="$selected_directory/source/repos"
        fi

        selected_project=$(ls -a $base_directory/$selected_directory | fzf)

        if [ -n "$selected_project" ]; then
            if [ $selected_project == "." ]; then
                selected_project=""
            elif [ $selected_project == "Django" ]; then
                selected_project="$selected_project/$(ls -a $base_directory/$selected_directory/$selected_project | fzf)"
            fi

            cd "$base_directory/$selected_directory/$selected_project"
            exec tmux new-session -s $selected_project 
            # exec zsh 
        else
            echo "No project selected"
        fi
    fi
else
    echo "No directory selected"
fi
