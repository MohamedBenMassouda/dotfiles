-- Default window and layer rules. Add your own in UserConfigs/WindowRules.lua
local rule = hl.window_rule
local half = { "monitor_w*0.7", "monitor_h*0.6" }

-- Spotify/Discord go to pop-up workspaces: see UserConfigs/Scratchpads.lua

----------------------------------------------------------------------
-- Tags: { match, tag }
----------------------------------------------------------------------
local tags = {
    { { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" }, "browser" },
    { { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, "browser" },
    { { class = "^(chrome-.+-Default)$" }, "browser" },
    { { class = "^([Cc]hromium)$" }, "browser" },
    { { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" }, "browser" },
    { { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, "browser" },
    { { class = "^([Tt]horium-browser|[Cc]achy-browser)$" }, "browser" },
    { { class = "^(zen-alpha|zen)$" }, "browser" },

    { { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" }, "notif" },

    { { title = "^(KooL Quick Cheat Sheet)$" }, "KooL_Cheat" },
    { { title = "^(KooL Hyprland Settings)$" }, "KooL_Settings" },
    { { class = "^(nwg-displays|nwg-look)$" }, "KooL-Settings" },

    { { class = "^(Alacritty|kitty|kitty-dropterm)$" }, "terminal" },

    { { class = "^([Tt]hunderbird|org.mozilla.Thunderbird)$" }, "email" },
    { { class = "^(eu.betterbird.Betterbird)$" }, "email" },
    { { class = "^(org.gnome.Evolution)$" }, "email" },

    { { class = "^(codium|codium-url-handler|VSCodium)$" }, "projects" },
    { { class = "^(VSCode|code|code-url-handler)$" }, "projects" },
    { { class = "^(jetbrains-.+)$" }, "projects" },
    { { class = "^(dev.zed.Zed|antigravity)$" }, "projects" },

    { { class = "^(com.obsproject.Studio)$" }, "screenshare" },

    { { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, "im" },
    { { class = "^([Ff]erdium)$" }, "im" },
    { { class = "^([Ww]hatsapp-for-linux)$" }, "im" },
    { { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, "im" },
    { { class = "^(teams-for-linux)$" }, "im" },
    { { class = "^(im.riot.Riot|Element)$" }, "im" },

    { { class = "^(gamescope)$" }, "games" },
    { { class = "^(steam_app_\\d+)$" }, "games" },
    { { class = "^([Ss]team)$" }, "gamestore" },
    { { title = "^([Ll]utris)$" }, "gamestore" },
    { { class = "^(com.heroicgameslauncher.hgl)$" }, "gamestore" },

    { { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, "file-manager" },
    { { class = "^(app.drey.Warp)$" }, "file-manager" },

    { { class = "^([Ww]aytrogen)$" }, "wallpaper" },

    { { class = "^([Aa]udacious)$" }, "multimedia" },
    { { class = "^([Mm]pv|vlc)$" }, "multimedia_video" },

    { { class = "^(wihotspot(-gui)?)$" }, "settings" },
    { { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, "settings" },
    { { class = "^(gnome-disks|wihotspot(-gui)?)$" }, "settings" },
    { { title = "(Kvantum Manager)" }, "settings" },
    { { class = "^(file-roller|org.gnome.FileRoller)$" }, "settings" },
    { { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, "settings" },
    { { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, "settings" },
    { { class = "^(qt5ct|qt6ct)$" }, "settings" },
    { { class = "(xdg-desktop-portal-gtk)" }, "settings" },
    { { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, "settings" },
    { { class = "^([Rr]ofi)$" }, "settings" },
    { { class = "^(btrfs-assistant)$" }, "settings" },
    { { class = "^(timeshift-gtk)$" }, "settings" },

    { { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, "viewer" },
    { { class = "^(evince)$" }, "viewer" },
    { { class = "^(eog|org.gnome.Loupe)$" }, "viewer" },
}
for _, t in ipairs(tags) do
    rule({ match = t[1], tag = "+" .. t[2] })
end

----------------------------------------------------------------------
-- Effects
----------------------------------------------------------------------
rule({ match = { tag = "multimedia_video" }, no_blur = true, opacity = "1.0" })
rule({ match = { tag = "multimedia" }, no_blur = true, opacity = "1.0" })

-- Center
rule({ match = { tag = "KooL_Cheat" }, center = true })
rule({ match = { tag = "KooL-Settings" }, center = true })
rule({ match = { title = "^(Keybindings)$" }, center = true })
rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
rule({ match = { class = "^([Ff]erdium)$" }, center = true })

-- Don't idle while anything is fullscreen
rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Float
rule({ match = { tag = "KooL_Cheat" }, float = true })
rule({ match = { tag = "wallpaper" }, float = true, center = true })
rule({ match = { tag = "settings" }, float = true, center = true })
rule({ match = { tag = "viewer" }, float = true, center = true })
rule({ match = { tag = "KooL-Settings" }, float = true, center = true })
rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)" }, float = true })
rule({ match = { class = "(org.gnome.Calculator|qalculate-gtk)" }, float = true })
rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
rule({ match = { class = "^([Ff]erdium)$" }, float = true })
rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
rule({ match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" }, float = true })
rule({ match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" }, float = true })
rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })
rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true, size = half, center = true })
rule({ match = { title = "^(Save As)$" }, float = true, size = half, center = true })
rule({ match = { initial_title = "(Open Files)" }, float = true, size = half })
rule({ match = { title = "^(SDDM Background)$" }, float = true, center = true, size = { "monitor_w*0.16", "monitor_h*0.12" } })
rule({ match = { class = "^(yad)$" }, float = true, center = true, size = { "monitor_w*0.2", "monitor_h*0.2" } })
rule({ match = { class = "^(hyprland-donate-screen)$" }, float = true, center = true })

-- Opacity (active inactive)
rule({ match = { tag = "browser" }, opacity = "0.99 0.8" })
rule({ match = { tag = "projects" }, opacity = "0.9 0.8" })
rule({ match = { tag = "im" }, opacity = "0.94 0.86" })
rule({ match = { tag = "multimedia" }, opacity = "0.94 0.86" })
rule({ match = { tag = "file-manager" }, opacity = "0.9 0.8" })
rule({ match = { tag = "terminal" }, opacity = "0.9 0.7" })
rule({ match = { tag = "settings" }, opacity = "0.8 0.7" })
rule({ match = { tag = "viewer" }, opacity = "0.82 0.75" })
rule({ match = { tag = "wallpaper" }, opacity = "0.9 0.7" })
rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" })
rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

-- Size
rule({ match = { tag = "KooL_Cheat" }, size = { "monitor_w*0.65", "monitor_h*0.9" } })
rule({ match = { tag = "wallpaper" }, size = { "monitor_w*0.7", "monitor_h*0.7" } })
rule({ match = { tag = "settings" }, size = { "monitor_w*0.7", "monitor_h*0.7" } })
rule({ match = { class = "^([Ff]erdium)$" }, size = { "monitor_w*0.6", "monitor_h*0.7" } })

-- Games
rule({ match = { tag = "games" }, no_blur = true, fullscreen = false })

-- No initial focus
rule({ match = { class = "^(jetbrains-.*)$" }, no_initial_focus = true })
rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })

----------------------------------------------------------------------
-- Layer rules
----------------------------------------------------------------------
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true, ignore_alpha = 0.5 })

----------------------------------------------------------------------
-- Named rules
----------------------------------------------------------------------
rule({
    name   = "Whatsapp-zapzap",
    match  = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
    size   = { "monitor_w*0.6", "monitor_h*0.7" },
    center = true,
})

rule({
    name              = "Picture-in-Picture",
    match             = { title = "^(Picture-in-Picture)$" },
    float             = true,
    move              = { "monitor_w*0.72", "monitor_h*0.07" },
    opacity           = "0.95 0.75",
    pin               = true,
    keep_aspect_ratio = true,
    size              = { "monitor_w*0.3", "monitor_h*0.3" },
})

rule({
    name   = "Thunar-Progress-bar",
    match  = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.26", "monitor_h*0.18" },
})
