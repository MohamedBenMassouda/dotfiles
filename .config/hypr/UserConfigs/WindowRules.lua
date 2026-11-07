-- Your window rules
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, stay_focused = true })
hl.window_rule({ match = { class = "^(bluetui)$" }, float = true, center = true, size = { "monitor_w*0.5", "monitor_h*0.6" } })
hl.window_rule({ match = { class = "^(notes)$" }, float = true, center = true, size = { "monitor_w*0.5", "monitor_h*0.6" } })
