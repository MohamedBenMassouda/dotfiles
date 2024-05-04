settings_file="$HOME/.config/hypr/UserConfigs/UserSettings.conf"

# Get the current setting.
followMouse=$(grep -i "follow_mouse" "$settings_file" | cut -d "=" -f 2)

# Toggle the setting.
# If the setting is 1, set it to 0.
# If the setting is 0, set it to 1.
if [ "$followMouse" -eq 1 ]; then
	sed -i 's/follow_mouse=1/follow_mouse=0/' "$settings_file"
else
	sed -i 's/follow_mouse=0/follow_mouse=1/' "$settings_file"
fi

followMouse=$(grep -i "follow_mouse" "$settings_file" | cut -d "=" -f 2)
notify-send "Follow mouse: $followMouse"

hyprctl reload
