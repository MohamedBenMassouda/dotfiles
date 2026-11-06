-- Pop-up workspaces: press the key to show/hide the app; opens it if not running.
local lib = require("lib")

local pads = {
    { key = "SUPER + Y", name = "music",   desc = "Spotify",
      class = "^([Ss]potify)$", cmd = "flatpak run com.spotify.Client" },
    { key = "SUPER + N", name = "chat",    desc = "Discord",
      class = "^([Dd]iscord)$", cmd = "discord" },
    { key = "SUPER + C", name = "monitor", desc = "System monitor (btop)",
      class = "^(btop-pad)$",   cmd = lib.term .. " --class btop-pad -e btop" },
}

for _, p in ipairs(pads) do
    local ws = "special:" .. p.name
    lib.bind(p.key, "Show/hide " .. p.desc, hl.dsp.workspace.toggle_special(p.name))
    -- launch the app the first time the empty pad is opened
    hl.workspace_rule({ workspace = ws, on_created_empty = lib.app(p.cmd) })
    hl.window_rule({ match = { class = p.class }, workspace = ws .. " silent" })
end

hl.window_rule({ match = { class = "^(btop-pad)$" }, float = true, center = true,
                 size = { "monitor_w*0.7", "monitor_h*0.7" } })

-- Spotify sets its class after the window opens, so rules miss it; catch it here.
hl.on("window.class", function(w)
    if w and w.class and w.class:match("^[Ss]potify$")
       and not (w.workspace and w.workspace.name == "special:music") then
        hl.dispatch(hl.dsp.window.move({ window = "address:" .. w.address, workspace = "special:music", follow = false }))
    end
end)
