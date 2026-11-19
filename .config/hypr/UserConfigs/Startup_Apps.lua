-- Your startup apps
local lib = require("lib")

hl.on("hyprland.start", function()
    -- music: spotify-player in the background once it's installed and signed in (about 50 MB,
    -- shows in the bar's media controls; `spotify_player` in a terminal opens its interface),
    -- else the Spotify app (about 1.9 GB across its processes)
    hl.exec_cmd(lib.app("sh -c 'if [ -f \"$HOME/.cache/spotify-player/credentials.json\" ] && spotify_player --help 2>/dev/null | grep -q -- --daemon; then exec spotify_player --daemon; else exec flatpak run com.spotify.Client; fi'"))
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
    hl.exec_cmd(lib.UserScripts .. "/Headphones.sh auto")  -- reconnect WH-CH720N if they're on
    -- game saves -> Windows folders, incl. games added to Steam since last time (GameLauncher.py)
    hl.exec_cmd(lib.UserScripts .. "/GameLauncher.py --share-saves")
end)
