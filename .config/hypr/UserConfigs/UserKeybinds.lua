-- Your keybinds. Default apps ($term, $files) come from UserConfigs/01-UserDefaults.conf
local lib = require("lib")
local s, us = lib.scriptsDir, lib.UserScripts
local exec = hl.dsp.exec_cmd
local bind, app = lib.bind, lib.app
-- same key again closes it (UserScripts/menu-toggle.sh)
local rofi = "bash -c 'source " .. us .. "/menu-toggle.sh; menu_toggle launcher && rofi -show drun -modi drun,filebrowser,run,window'"

bind("SUPER + Super_L", "App launcher (tap SUPER)", exec(rofi), { release = true })
bind("SUPER + D", "App launcher", exec(rofi))
bind("SUPER + SHIFT + Return", "Dropdown terminal", exec(s .. "/Dropterminal.sh " .. lib.term))
bind("SUPER + Return", "Terminal", exec(app(lib.term)))
bind("SUPER + E", "File manager", exec(app(lib.files)))
bind("SUPER + SHIFT + O", "Change oh-my-zsh theme", exec(us .. "/ZshChangeTheme.sh"))
bind("SUPER + SHIFT + D", "Color picker", exec("hyprpicker -a"))
bind("SUPER + CTRL + H", "Open Hyprland wiki", exec("xdg-open https://wiki.hypr.land/"))
bind("SUPER + V", "Clipboard history", exec(s .. "/ClipManager.sh"))
bind("SUPER + SHIFT + V", "Clipboard images", exec(us .. "/ClipImages.sh"))
bind("ALT + Tab", "Next window", hl.dsp.window.cycle_next())
bind("ALT + SHIFT + Tab", "Previous window", hl.dsp.window.cycle_next({ next = false }))
bind("SUPER + L", "Lock screen", exec(s .. "/LockScreen.sh"))
bind("SUPER + J", "Toggle focus-follows-mouse", function()
    local on = hl.get_config("input.follow_mouse") ~= 0
    hl.config({ input = { follow_mouse = on and 0 or 1 } })
    hl.notification.create({ text = "Focus follows mouse: " .. (on and "off" or "on"), timeout = 1500 })
end)
bind("SUPER + K", "Keybind cheat sheet", exec(s .. "/KeyBinds.sh"))
bind("SUPER + SHIFT + W", "Random wallpaper", exec(us .. "/WallpaperRandom.sh"))
-- Rofi menus
bind("SUPER + T", "Open project (tmux)", exec(us .. "/ProjectPicker.sh"))
bind("SUPER + X", "Switch to window", exec(us .. "/WindowSwitcher.sh"))
bind("SUPER + ALT + A", "Audio output/input", exec(us .. "/AudioSwitch.sh"))
bind("SUPER + CTRL + G", "Game launcher", exec(us .. "/GameLauncher.py"))
bind("SUPER + A", "Overview", exec("pkill rofi || true && agsv1 -t 'overview'"))
bind("SUPER + P", "Media controls", exec(us .. "/MediaMenu.sh"))
bind("SUPER + SHIFT + P", "Screenshot menu", exec(us .. "/ScreenshotMenu.sh"))
bind("SUPER + SHIFT + L", "Brightness menu", exec(us .. "/BrightnessMenu.sh"))
bind("SUPER + ALT + G", "Switch primary GPU (next login)", exec(us .. "/GpuPrimary.sh toggle"))
bind("SUPER + ALT + P", "Cycle power profile", exec(us .. "/PowerProfile.sh"))
bind("SUPER + SHIFT + R", "Start/stop screen recording", exec(us .. "/ScreenRecord.sh"))
bind("SUPER + ALT + H", "Connect/disconnect headphones", exec(us .. "/Headphones.sh"))
bind("SUPER + ALT + T", "Bluetooth manager", exec("command -v bluetui >/dev/null && " .. lib.term .. " --class bluetui -e bluetui || blueman-manager"))

-- Media
bind("SUPER + ALT + Right", "Next track", exec(s .. "/MediaCtrl.sh --nxt"))
bind("SUPER + ALT + Left", "Previous track", exec(s .. "/MediaCtrl.sh --prv"))
bind("SUPER + ALT + X", "Stop media", exec(s .. "/MediaCtrl.sh --stop"))
bind("SUPER + ALT + Space", "Play/pause", exec(s .. "/MediaCtrl.sh --pause"))
bind("SUPER + ALT + Up", "Volume up", exec(s .. "/Volume.sh --inc"), { repeating = true })
bind("SUPER + ALT + Down", "Volume down", exec(s .. "/Volume.sh --dec"), { repeating = true })
