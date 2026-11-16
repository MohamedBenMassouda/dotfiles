-- Turn off animations, blur and shadows while a game window is open; restore when the last one closes.
-- The settings to restore are kept in a file, not a Lua variable: a config reload re-runs this
-- file and used to forget them, so the theme pack stayed paused and couch mode
-- (scripts/ControllerDesk.py) thought a game was still running.
-- If game mode is already on (SUPER+SHIFT+G, or GameRun.sh for launcher games), this leaves it alone.
local runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local paused_flag = runtime .. "/desktop-pack-paused"   -- game mode is on (scripts/Pack.sh)
local marker = runtime .. "/auto-game-mode"             -- this file turned it on; holds the old settings
local pack = os.getenv("HOME") .. "/.config/hypr/scripts/Pack.sh"

local function exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end

local function is_game(w)
    if not w then return false end
    local c = w.class or ""
    return c:match("^steam_app_%d+$") or c == "gamescope" or w.content_type == "game"
end

local function games_open(except)
    for _, w in ipairs(hl.get_windows()) do
        if w.address ~= except and is_game(w) then return true end
    end
    return false
end

local function quiet()
    hl.config({
        animations = { enabled = false },
        decoration = { blur = { enabled = false }, shadow = { enabled = false } },
    })
end

local function start()
    local f = io.open(marker, "w")
    f:write(tostring(hl.get_config("animations.enabled")), " ",
            tostring(hl.get_config("decoration.blur.enabled")), " ",
            tostring(hl.get_config("decoration.shadow.enabled")))
    f:close()
    quiet()
    hl.exec_cmd(pack .. " pause")   -- theme pack off while gaming
    hl.exec_cmd("qs ipc call osd toast game 'Game mode' 'On while a game is open'")
end

local function stop()
    local f = io.open(marker)
    local anim, blur, shadow = f:read("*a"):match("(%a+) (%a+) (%a+)")
    f:close()
    os.remove(marker)
    hl.config({
        animations = { enabled = anim ~= "false" },
        decoration = { blur = { enabled = blur ~= "false" }, shadow = { enabled = shadow ~= "false" } },
    })
    hl.exec_cmd(pack .. " resume")
    hl.exec_cmd("qs ipc call osd toast game 'Game mode' 'Off'")
end

hl.on("window.open", function(w)
    if not is_game(w) or exists(marker) or exists(paused_flag) then return end
    start()
end)

hl.on("window.close", function(w)
    if not exists(marker) or not is_game(w) or games_open(w.address) then return end
    stop()
end)

-- after a reload: a game still open gets the quiet settings back (the reload reset them);
-- if the game closed meanwhile, finish turning game mode off
if exists(marker) then
    if games_open() then quiet() else stop() end
end
