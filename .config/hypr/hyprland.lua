-- Hyprland Lua config (converted from the JaKooLit hyprland.conf setup).
-- Defaults live in configs/, your overrides in UserConfigs/ (loaded after, so they win).
-- Wiki: https://wiki.hypr.land/configuring/

require("configs/Keybinds")

require("configs/Startup_Apps")
require("UserConfigs/Startup_Apps")

require("configs/ENVariables")
require("UserConfigs/ENVariables")

require("configs/Laptops")

require("configs/WindowRules")
require("UserConfigs/WindowRules")

require("configs/SystemSettings")

require("UserConfigs/UserDecorations")
require("UserConfigs/UserAnimations")
require("UserConfigs/UserKeybinds")
require("UserConfigs/UserSettings")
require("UserConfigs/Scratchpads")
require("UserConfigs/AutoGameMode")

-- nwg-displays
require("monitors")
require("workspaces")
