-- Shared helpers for the Lua config.
local M = {}

M.home        = os.getenv("HOME")
M.hypr        = M.home .. "/.config/hypr"
M.scriptsDir  = M.hypr .. "/scripts"
M.UserScripts = M.hypr .. "/UserScripts"

-- Read `$name = value` lines from a hyprlang file.
-- Lets wallust and the KooL scripts keep writing their .conf files unchanged.
function M.read_vars(path)
    local vars = {}
    local f = io.open(path, "r")
    if not f then return vars end
    for line in f:lines() do
        local k, v = line:match("^%s*%$([%w_]+)%s*=%s*([^#]-)%s*$")
        if k then vars[k] = v end
    end
    f:close()
    return vars
end

-- wallust colors ($color0..15, $background, $foreground)
M.colors = M.read_vars(M.hypr .. "/wallust/wallust-hyprland.conf")

-- User default apps ($term, $files, $edit, $Search_Engine)
M.defaults = M.read_vars(M.hypr .. "/UserConfigs/01-UserDefaults.conf")
M.term  = M.defaults.term  or "kitty"
M.files = M.defaults.files or "thunar"

-- Session started via "Hyprland (uwsm-managed)" in GDM? uwsm runs Hyprland as a
-- systemd service, so INVOCATION_ID is set; a plain GDM session has neither.
M.uwsm = os.getenv("DESKTOP_SESSION") == "hyprland-uwsm" or os.getenv("INVOCATION_ID") ~= nil

-- Launch an app; under uwsm it runs as its own systemd unit (cleaner logout, logs in journal)
function M.app(cmd)
    return M.uwsm and ("uwsm-app -- " .. cmd) or cmd
end

-- hl.bind with a description (shown in `hyprctl binds` and the SUPER+K cheat sheet)
function M.bind(keys, desc, dsp, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dsp, opts)
end

return M
