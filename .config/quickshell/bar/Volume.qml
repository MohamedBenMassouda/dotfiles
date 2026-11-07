import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// Output volume. Scroll: ±5%, left click: audio switcher, right click: mute.
Label {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    // keeps the sink's audio properties live
    PwObjectTracker {
        objects: [root.sink]
    }

    text: (muted ? "󰝟" : percent > 60 ? "󰕾" : percent > 25 ? "󰖀" : "󰕿") + "  " + percent + "%"
    color: muted ? Theme.dim : Theme.volume

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
            } else {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/UserScripts/AudioSwitch.sh"]);
            }
        }
        onWheel: wheel => {
            if (!root.sink?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
