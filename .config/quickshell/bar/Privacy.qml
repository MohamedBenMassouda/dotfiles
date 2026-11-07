import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs

// Red icons while something records the mic, uses the camera or shares the
// screen (read from PipeWire links; cava listens to the speakers, not the mic,
// so it doesn't count). Hidden otherwise.
RowLayout {
    readonly property var links: Pipewire.links.values
    readonly property bool mic: links.some(l => l.source?.type === PwNodeType.AudioSource && l.target?.isStream)
    readonly property bool camera: links.some(l => l.source?.type === PwNodeType.VideoSource && !/^xdph/.test(l.source?.name ?? ""))
    readonly property bool screen: Pipewire.nodes.values.some(n => n.type === PwNodeType.VideoSource && /^xdph/.test(n.name))

    visible: mic || camera || screen
    spacing: 6

    Label { visible: parent.mic; text: String.fromCodePoint(0xF036C); color: Theme.urgent }
    Label { visible: parent.camera; text: String.fromCodePoint(0xF05A0); color: Theme.urgent }
    Label { visible: parent.screen; text: String.fromCodePoint(0xF1483); color: Theme.urgent }
}
