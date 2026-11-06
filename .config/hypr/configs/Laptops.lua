-- Laptop keys and touchpad
local lib = require("lib")
local s = lib.scriptsDir
local exec = hl.dsp.exec_cmd
local bind = lib.bind
local rep = { repeating = true }

bind("XF86KbdBrightnessDown", "Keyboard backlight down", exec(s .. "/BrightnessKbd.sh --dec"), rep)
bind("XF86KbdBrightnessUp", "Keyboard backlight up", exec(s .. "/BrightnessKbd.sh --inc"), rep)
bind("XF86MonBrightnessDown", "Screen brightness down", exec(s .. "/Brightness.sh --dec"), rep)
bind("XF86MonBrightnessUp", "Screen brightness up", exec(s .. "/Brightness.sh --inc"), rep)
bind("XF86TouchpadToggle", "Touchpad on/off", exec(s .. "/TouchPad.sh"))

-- Screenshots for laptops without a Print key
bind("SUPER + F6", "Screenshot", exec(s .. "/ScreenShot.sh --now"))
bind("SUPER + SHIFT + F6", "Screenshot area", exec(s .. "/ScreenShot.sh --area"))
bind("SUPER + CTRL + F6", "Screenshot in 5s", exec(s .. "/ScreenShot.sh --in5"))
bind("SUPER + ALT + F6", "Screenshot in 10s", exec(s .. "/ScreenShot.sh --in10"))
bind("ALT + F6", "Screenshot active window", exec(s .. "/ScreenShot.sh --active"))

hl.device({
    name    = "elan0710:01-04f3:30ed-touchpad",
    enabled = true,
})
