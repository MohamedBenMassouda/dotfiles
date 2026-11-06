-- Your startup apps
local lib = require("lib")

hl.on("hyprland.start", function()
    hl.exec_cmd(lib.app("flatpak run com.spotify.Client")) -- opens hidden on SUPER+Y
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(lib.UserScripts .. "/MusicNotify.sh")
    hl.exec_cmd(lib.UserScripts .. "/Headphones.sh auto")  -- reconnect WH-CH720N if they're on
end)
