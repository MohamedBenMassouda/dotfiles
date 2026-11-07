import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Microphone. Click: mute/unmute, scroll: ±5%.
Label {
    id: root

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: source?.audio?.muted ?? true
    readonly property int percent: Math.round((source?.audio?.volume ?? 0) * 100)

    PwObjectTracker {
        objects: [root.source]
    }

    visible: source !== null
    text: String.fromCodePoint(muted ? 0xF036D : 0xF036C) + " " + percent + "%"
    color: muted ? Theme.urgent : Theme.mic

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        onWheel: wheel => {
            if (!root.source?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.source.audio.volume = Math.max(0, Math.min(1, root.source.audio.volume + step));
        }
    }
}
