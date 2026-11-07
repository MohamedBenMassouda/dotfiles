#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Pre-configured Monitor Profiles

# Check if rofi is already running
source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
menu_toggle MonitorProfiles || exit 0

# Variables
iDIR="$HOME/.config/hypr/assets/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
monitor_dir="$HOME/.config/hypr/Monitor_Profiles"
target="$HOME/.config/hypr/monitors.lua"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
msg='❗NOTE:❗ This will overwrite $HOME/.config/hypr/monitors.lua'

# Define the list of files to ignore
ignore_files=(
  "README"
)

# list of Monitor Profiles, sorted alphabetically with numbers first
mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

# Remove ignored files from the list
for ignored_file in "${ignore_files[@]}"; do
    mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done

# Rofi Menu
chosen_file=$(echo "$mon_profiles_list" | rofi -i -dmenu -p Monitors -config $rofi_theme -mesg "$msg")

if [[ -n "$chosen_file" ]]; then
    full_path="$monitor_dir/$chosen_file.conf"
    # profiles stay in hyprlang; convert monitor= lines to hl.monitor()
    awk -F, -v src="$chosen_file" 'BEGIN { print "-- Monitor profile: " src }
      /^[ \t]*monitor[ \t]*=/ {
        sub(/^[^=]*=[ \t]*/, "", $1); for (i = 1; i <= NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i)
        if ($2 == "disable") { printf "hl.monitor({ output = \"%s\", disabled = true })\n", $1; next }
        printf "hl.monitor({ output = \"%s\", mode = \"%s\", position = \"%s\", scale = \"%s\" })\n", $1, $2, $3, $4
      }' "$full_path" > "$target"
    
    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
${SCRIPTSDIR}/RefreshNoWaybar.sh &