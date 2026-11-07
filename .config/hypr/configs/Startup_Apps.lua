-- Default startup apps. Add your own in UserConfigs/Startup_Apps.lua
local lib = require("lib")
local s = lib.scriptsDir
local app = lib.app  -- runs via uwsm-app in a uwsm session

-- Video wallpaper chosen in WallpaperSelect.sh? (path stored in this file)
local live = io.open(lib.hypr .. "/wallpaper_effects/.live_wallpaper", "r")
local livewallpaper = live and live:read("l")
if live then live:close() end

hl.on("hyprland.start", function()
    if livewallpaper and livewallpaper ~= "" then
        hl.exec_cmd(app("mpvpaper '*' -o 'load-scripts=no no-audio --loop' '" .. livewallpaper .. "'"))
    else
        hl.exec_cmd(app("awww-daemon --format xrgb"))
    end
    if not lib.uwsm then -- uwsm exports the environment itself
        hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
        hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE")
    end
    hl.exec_cmd(s .. "/Dropterminal.sh kitty")
    hl.exec_cmd(s .. "/Polkit.sh")
    hl.exec_cmd(app("nm-applet --indicator"))
    hl.exec_cmd(app("kdeconnectd"))  -- phone: notifications, battery, file sharing (quick settings)
    hl.exec_cmd(app("qs"))         -- bar, flyouts, notifications, panels (~/.config/quickshell); to go back: app("waybar") + app("swaync")
    hl.exec_cmd(app("hypridle"))
    hl.exec_cmd(s .. "/Hyprsunset.sh init")
    hl.exec_cmd(app("wl-paste --type text --watch cliphist store"))
    hl.exec_cmd(app("wl-paste --type image --watch cliphist store"))
end)
