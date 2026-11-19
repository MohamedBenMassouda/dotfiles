-- Your startup apps
local lib = require("lib")

hl.on("hyprland.start", function()
    -- music: Spotifast starts itself in the tray, from its own "start at login" setting
    -- (~/.config/autostart/spotifast.desktop, not in this repo); scripts/PlayerVolume.sh
    -- brings back its volume, which its Soloist player resets to 100%
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(lib.UserScripts .. "/Headphones.sh auto")  -- reconnect WH-CH720N if they're on
    -- game saves -> Windows folders, incl. games added to Steam since last time (GameLauncher.py)
    hl.exec_cmd(lib.UserScripts .. "/GameLauncher.py --share-saves")
end)
