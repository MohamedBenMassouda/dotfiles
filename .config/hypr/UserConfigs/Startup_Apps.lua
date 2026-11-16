-- Your startup apps
local lib = require("lib")

hl.on("hyprland.start", function()
    hl.exec_cmd(lib.app("flatpak run com.spotify.Client"))
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(lib.UserScripts .. "/Headphones.sh auto")  -- reconnect WH-CH720N if they're on
    -- game saves -> Windows folders, incl. games added to Steam since last time (GameLauncher.py)
    hl.exec_cmd(lib.UserScripts .. "/GameLauncher.py --share-saves")
end)
