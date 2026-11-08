#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations

notif="$HOME/.config/hypr/assets/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


HYPRGAMEMODE=$(hyprctl repl 'hl.get_config("animations.enabled")')
if [ "$HYPRGAMEMODE" = true ] ; then
    hyprctl eval '
      hl.config({
        animations = { enabled = false },
        decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
        general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
      })
      hl.window_rule({ match = { class = ".*" }, opacity = "1 override 1 override 1 override" })'
    awww kill 
    "$SCRIPTSDIR/Pack.sh" pause      # theme pack off while gaming
    qs ipc call osd toast game "Game mode" "On" >/dev/null 2>&1 || notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    sleep 0.1
    exit
else
	awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
	sleep 0.1
	"$SCRIPTSDIR/Pack.sh" resume
	${SCRIPTSDIR}/WallustSwww.sh
	sleep 0.5
  hyprctl reload
	${SCRIPTSDIR}/Refresh.sh	 
    qs ipc call osd toast game "Game mode" "Off" >/dev/null 2>&1 || notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
hyprctl reload
