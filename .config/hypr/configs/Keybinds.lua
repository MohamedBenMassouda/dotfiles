-- Default keybinds. Put your own in UserConfigs/UserKeybinds.lua
local lib = require("lib")
local s, us = lib.scriptsDir, lib.UserScripts
local exec = hl.dsp.exec_cmd
local bind = lib.bind
local function m(keys) return "SUPER + " .. keys end

-- Power: hyprshutdown closes apps gracefully first
bind("CTRL + ALT + Delete", "Log out", exec("hyprshutdown -t 'Logging out...'"))
bind("CTRL + ALT + End", "Shut down", exec("hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'"))
bind("CTRL + ALT + Home", "Restart", exec("hyprshutdown -t 'Restarting...' --post-cmd 'systemctl reboot'"))
bind("CTRL + ALT + P", "Power menu", exec(lib.UserScripts .. "/PowerMenu.sh"))
bind("CTRL + ALT + L", "Lock screen", exec(s .. "/LockScreen.sh"))

-- Windows
bind(m("Q"), "Close window", hl.dsp.window.close())
bind(m("SHIFT + Q"), "Close window", hl.dsp.window.close())
bind(m("F"), "Fullscreen", hl.dsp.window.fullscreen())
bind(m("M"), "Maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(m("SHIFT + F"), "Toggle floating", hl.dsp.window.float({ action = "toggle" }))

-- KooL scripts
bind(m("ALT + R"), "Refresh colours, rofi", exec(s .. "/Refresh.sh"))
bind("CTRL + SHIFT + W", "Refresh colours, rofi", exec(s .. "/Refresh.sh"))
bind(m("SHIFT + E"), "Emoji picker", exec(s .. "/RofiEmoji.sh"))
bind(m("S"), "Web search (rofi)", exec(s .. "/RofiSearch.sh"))
bind(m("SHIFT + B"), "Toggle blur strength", exec(s .. "/ChangeBlur.sh"))
bind(m("SHIFT + G"), "Game mode on/off", exec(s .. "/GameMode.sh"))
bind(m("ALT + L"), "Switch master/dwindle layout", exec(s .. "/ChangeLayout.sh"))
bind(m("H"), "Notification panel", exec("qs ipc call panel toggle notifications"))
bind(m("N"), "Quick settings", exec("qs ipc call panel toggle control"))
bind(m("SHIFT + M"), "Online music (rofi)", exec(us .. "/RofiBeats.sh"))
bind(m("W"), "Choose wallpaper", exec(us .. "/WallpaperSelect.sh"))
bind("CTRL + ALT + W", "Random wallpaper", exec(us .. "/WallpaperRandom.sh"))
bind(m("B"), "Show/hide bar", exec("qs ipc call bar toggle"))

-- Master layout
bind(m("CTRL + D"), "Remove master", hl.dsp.layout("removemaster"))
bind(m("I"), "Add master", hl.dsp.layout("addmaster"))
bind(m("CTRL + Return"), "Swap with master", hl.dsp.layout("swapwithmaster"))

-- Groups
bind(m("G"), "Toggle window group", hl.dsp.group.toggle())
bind("ALT + Tab", "Next window in group", hl.dsp.group.next())

-- Media / special keys
bind("XF86AudioRaiseVolume", "Volume up", exec(s .. "/Volume.sh --inc"))
bind("XF86AudioLowerVolume", "Volume down", exec(s .. "/Volume.sh --dec"))
bind("XF86AudioMicMute", "Mute mic", exec(s .. "/Volume.sh --toggle-mic"))
bind("XF86AudioMute", "Mute", exec(s .. "/Volume.sh --toggle"))
bind("XF86Sleep", "Suspend", exec("systemctl suspend"))
bind("XF86RFKill", "Airplane mode", exec(s .. "/AirplaneMode.sh"))
bind("XF86AudioPause", "Play/pause", exec(s .. "/MediaCtrl.sh --pause"))
bind("XF86AudioPlay", "Play/pause", exec(s .. "/MediaCtrl.sh --pause"))
bind("XF86AudioNext", "Next track", exec(s .. "/MediaCtrl.sh --nxt"))
bind("XF86AudioPrev", "Previous track", exec(s .. "/MediaCtrl.sh --prv"))
bind("XF86AudioStop", "Stop media", exec(s .. "/MediaCtrl.sh --stop"))
bind("Caps_Lock", "Caps Lock flyout", exec(s .. "/CapsLock.sh"), { release = true, non_consuming = true, ignore_mods = true })

-- Screenshots
bind(m("Print"), "Screenshot", exec(s .. "/ScreenShot.sh --now"))
bind(m("SHIFT + Print"), "Screenshot area", exec(s .. "/ScreenShot.sh --area"))
bind(m("CTRL + Print"), "Screenshot in 5s", exec(s .. "/ScreenShot.sh --in5"))
bind(m("ALT + Print"), "Screenshot in 10s", exec(s .. "/ScreenShot.sh --in10"))
bind("ALT + Print", "Screenshot active window", exec(s .. "/ScreenShot.sh --active"))
bind(m("SHIFT + S"), "Screenshot (hyprshot)", exec(s .. "/HyprShot.sh"))
bind(m("ALT + S"), "Screenshot to clipboard", exec(s .. "/HyprShot.sh --clipboard"))

-- Resize / move / focus with arrows
local dirs = { left = { -50, 0 }, right = { 50, 0 }, up = { 0, -50 }, down = { 0, 50 } }
for dir, d in pairs(dirs) do
    bind(m("SHIFT + " .. dir), "Resize window " .. dir, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    bind(m("CTRL + " .. dir), "Move window " .. dir, hl.dsp.window.move({ direction = dir }))
    bind(m(dir), "Focus " .. dir, hl.dsp.focus({ direction = dir }))
end

-- Workspaces
bind(m("Tab"), "Next workspace on monitor", hl.dsp.focus({ workspace = "m+1" }))
bind(m("SHIFT + Tab"), "Previous workspace on monitor", hl.dsp.focus({ workspace = "m-1" }))
bind(m("SHIFT + U"), "Move window to scratch workspace", hl.dsp.window.move({ workspace = "special:special" }))
bind(m("U"), "Show/hide scratch workspace", hl.dsp.workspace.toggle_special("special"))

-- code:10..19 = number row 1..0, works on any keyboard layout
for i = 1, 10 do
    local key = "code:" .. (i + 9)
    bind(m(key), "Workspace " .. i, hl.dsp.focus({ workspace = i }))
    bind(m("SHIFT + " .. key), "Move window to workspace " .. i, hl.dsp.window.move({ workspace = i }))
    bind(m("CTRL + " .. key), "Send window to workspace " .. i .. " (stay)", hl.dsp.window.move({ workspace = i, follow = false }))
end
bind(m("SHIFT + bracketleft"), "Move window to previous workspace", hl.dsp.window.move({ workspace = "-1" }))
bind(m("SHIFT + bracketright"), "Move window to next workspace", hl.dsp.window.move({ workspace = "+1" }))
bind(m("CTRL + bracketleft"), "Send window to previous workspace (stay)", hl.dsp.window.move({ workspace = "-1", follow = false }))
bind(m("CTRL + bracketright"), "Send window to next workspace (stay)", hl.dsp.window.move({ workspace = "+1", follow = false }))

bind(m("mouse_down"), "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind(m("mouse_up"), "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind(m("period"), "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
bind(m("comma"), "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize
bind(m("mouse:272"), "Drag window", hl.dsp.window.drag(), { mouse = true })
bind(m("mouse:273"), "Resize window with mouse", hl.dsp.window.resize(), { mouse = true })
