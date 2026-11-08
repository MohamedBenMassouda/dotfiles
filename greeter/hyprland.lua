-- Compositor for the login screen (greetd runs it as the "greeter" user).
-- Installed to /etc/greetd/greeter/ by greeter/install.sh. It uses a copy of
-- your own monitor layout, kept up to date by greeter-sync (systemd path unit),
-- so the login screen appears on the same monitors as your desktop.
local dir = "/etc/greetd/greeter/"

dofile(dir .. "monitors.lua")

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = 0x13111A,
    },
    animations = { enabled = false },
    decoration = { blur = { enabled = false }, shadow = { enabled = false } },
    cursor = { inactive_timeout = 0 },
    xwayland = { enabled = false },   -- no X11 apps on the login screen
})

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")

-- the login screen; when it quits (you logged in, or it crashed) close this
-- compositor so greetd can start your session / the fallback
hl.on("hyprland.start", function()
    -- qs failing (e.g. a QML error) leaves a flag: start-greeter.sh then falls
    -- back to the text login instead of starting this again and again
    hl.exec_cmd("sh -c 'qs -p " .. dir .. "quickshell/shell.qml || touch \"$HOME/greeter-failed\"; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
