import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs

// Audio visualiser (cava). Only runs while something is playing, so it costs
// nothing when idle.
Label {
    id: root

    readonly property string blocks: "▁▂▃▄▅▆▇█"
    readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)

    visible: playing
    text: "▁".repeat(12)
    color: Theme.accent
    font.family: Theme.font

    Process {
        running: root.playing
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]

        stdout: SplitParser {
            onRead: data => root.text = data.split(";").filter(v => v !== "").map(v => root.blocks[Number(v)] ?? "▁").join("")
        }
    }
}
