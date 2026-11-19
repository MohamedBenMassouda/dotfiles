import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs

// Audio visualiser (cava). Only runs while something is playing, so it costs
// nothing when idle, and stops while this screen shows a fullscreen window (a game or
// video): its 30 redraws a second kept the compositor busy behind it.
Label {
    id: root

    readonly property string blocks: "▁▂▃▄▅▆▇█"
    property ShellScreen screen
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool fullscreenHere: Hyprland.monitorFor(screen)?.activeWorkspace?.hasFullscreen ?? false

    visible: playing
    text: "▁".repeat(12)
    color: Theme.accent
    font.family: Theme.font

    Process {
        running: root.playing && !root.fullscreenHere
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]

        stdout: SplitParser {
            onRead: data => root.text = data.split(";").filter(v => v !== "").map(v => root.blocks[Number(v)] ?? "▁").join("")
        }
    }
}
