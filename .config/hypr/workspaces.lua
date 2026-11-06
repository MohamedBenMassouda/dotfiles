-- Odd workspaces on laptop screen, even on HDMI (was workspaces.conf from nwg-displays)
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = (i % 2 == 1) and "eDP-1" or "HDMI-A-1",
        default   = i <= 2,
    })
end
