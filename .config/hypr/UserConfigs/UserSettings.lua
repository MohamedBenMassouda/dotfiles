-- Your settings (override configs/SystemSettings.lua)
hl.config({
    misc = {
        on_focus_under_fullscreen = 1,
    },
})

-- 3-finger swipe left/right to switch workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Flat accel for gaming mice
hl.device({ name = "pixart-gaming-mouse", accel_profile = "flat" })
hl.device({ name = "compx-2.4g-wireless-receiver-mouse", accel_profile = "flat" })
