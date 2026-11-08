-- Turn off animations, blur and shadows while a game window is open; restore when the last one closes.
local function is_game(w)
    if not w then return false end
    local c = w.class or ""
    return c:match("^steam_app_%d+$") or c == "gamescope" or w.content_type == "game"
end

local saved

local function games_open(except)
    for _, w in ipairs(hl.get_windows()) do
        if w.address ~= except and is_game(w) then return true end
    end
    return false
end

hl.on("window.open", function(w)
    if saved or not is_game(w) then return end
    saved = {
        anim   = hl.get_config("animations.enabled"),
        blur   = hl.get_config("decoration.blur.enabled"),
        shadow = hl.get_config("decoration.shadow.enabled"),
    }
    hl.config({
        animations = { enabled = false },
        decoration = { blur = { enabled = false }, shadow = { enabled = false } },
    })
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/Pack.sh pause")   -- theme pack off while gaming
    hl.exec_cmd("qs ipc call osd toast game 'Game mode' 'On while a game is open'")
end)

hl.on("window.close", function(w)
    if not saved or not is_game(w) or games_open(w.address) then return end
    hl.config({
        animations = { enabled = saved.anim },
        decoration = { blur = { enabled = saved.blur }, shadow = { enabled = saved.shadow } },
    })
    saved = nil
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/Pack.sh resume")
    hl.exec_cmd("qs ipc call osd toast game 'Game mode' 'Off'")
end)
