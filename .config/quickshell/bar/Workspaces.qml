import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Kanji workspace numbers: every workspace that exists on any monitor, plus
// the active one. Workspaces living on the other monitor are faded. Click to switch, scroll to move through them.
RowLayout {
    id: root

    required property string screenName
    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screenName)

    spacing: 4

    // "Droid Sans" is one family name for many files (Latin, Thai, Arabic...);
    // load the Japanese one directly so every kanji renders.
    FontLoader {
        id: kanjiFont
        source: "file:///usr/share/fonts/droid/DroidSansJapanese.ttf"
    }

    Repeater {
        model: 10

        delegate: Rectangle {
            id: ws

            required property int index
            readonly property int number: index + 1
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === number)
            readonly property bool active: root.monitor?.activeWorkspace?.id === number
            readonly property bool onThisMonitor: workspace?.monitor?.name === root.screenName

            visible: active || workspace !== undefined
            opacity: active || onThisMonitor ? 1 : 0.35
            implicitWidth: 26
            implicitHeight: 24
            radius: 6
            color: active ? Theme.accent : (mouse.containsMouse ? Theme.surface : "transparent")

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Label {
                anchors.centerIn: parent
                text: root.kanji[ws.index]
                font.family: kanjiFont.name
                color: ws.workspace?.urgent ? Theme.urgent : (ws.active ? Theme.foreground : Theme.dim)
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${ws.number} })`])
            }
        }
    }

    WheelHandler {
        onWheel: event => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${event.angleDelta.y > 0 ? "m-1" : "m+1"}" })`])
    }
}
