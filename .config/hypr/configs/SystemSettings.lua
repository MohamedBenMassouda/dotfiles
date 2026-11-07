-- Default Hyprland settings. Override in UserConfigs/UserSettings.lua / UserDecorations.lua
local c = require("lib").colors

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact      = 0.5,
    },

    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        resize_on_border = true,
        layout           = "master",
        col = {
            active_border   = c.color0,
            inactive_border = c.background,
        },
    },

    group = {
        col      = { border_active = c.color15 },
        groupbar = { col = { active = c.color0 } },
    },

    decoration = {
        rounding           = 8,
        active_opacity     = 1.0,
        inactive_opacity   = 0.9,
        fullscreen_opacity = 1.0,
        dim_inactive       = true,
        dim_strength       = 0.1,
        blur = {
            enabled           = true,
            size              = 5,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
        },
        shadow = {
            enabled        = true,
            range          = 6,
            render_power   = 1,
            color_inactive = "0x50000000",
        },
    },

    input = {
        kb_layout                   = "us",
        kb_options                  = "grp:alt_shift_toggle",
        repeat_rate                 = 50,
        repeat_delay                = 300,
        numlock_by_default          = true,
        left_handed                 = false,
        follow_mouse                = 1,
        float_switch_override_focus = 0,
        touchpad = {
            disable_while_typing    = true,
            natural_scroll          = true,
            clickfinger_behavior    = false,
            middle_button_emulation = true,
            tap_to_click            = true,
            drag_lock               = 0,
        },
    },

    gestures = {
        workspace_swipe_distance           = 400,
        workspace_swipe_invert             = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio       = 0.5,
        workspace_swipe_create_new         = true,
        workspace_swipe_forever            = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        vrr                      = 0,
        enable_swallow           = true,
        focus_on_activate        = false,
        swallow_regex            = "^(kitty)$",
        allow_session_lock_restore = true,  -- a crashed lock screen can be restarted (QsLock.sh / hyprlock)
    },

    binds = {
        workspace_back_and_forth = 1,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-- Special workspaces (scratch / pop-ups): windows sit inset from the screen edges,
-- about 80% of it (replaces the deprecated dwindle.special_scale_factor = 0.8)
hl.workspace_rule({ workspace = "s[true]", gaps_out = { top = 90, bottom = 90, left = 170, right = 170 } })
