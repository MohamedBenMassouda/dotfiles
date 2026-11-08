import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Kanji workspace numbers: every workspace that exists on any monitor, plus
// the active one. Workspaces living on the other monitor are faded. Click to switch, scroll to move through them.
// A little spider hangs on a thread over the active one and swings across
// when you switch.
Item {
    id: root

    required property string screenName
    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screenName)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // "Droid Sans" is one family name for many files (Latin, Thai, Arabic...);
    // load the Japanese one directly so every kanji renders.
    FontLoader {
        id: kanjiFont
        source: "file:///usr/share/fonts/droid/DroidSansJapanese.ttf"
    }

    RowLayout {
    id: row
    spacing: 4

    Repeater {
        id: buttons
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

    }

    // ---- the spider: hangs from the top of the island over the active workspace ----
    readonly property int activeIndex: (monitor?.activeWorkspace?.id ?? 1) - 1
    readonly property Item activeButton: buttons.count > activeIndex ? buttons.itemAt(activeIndex) : null
    readonly property real target: activeButton ? activeButton.x + activeButton.width - 5 : 0

    Item {
        id: hanger
        x: root.target - width / 2
        y: -(Theme.barHeight - root.height) / 2       // the island's top edge
        width: 12
        height: (Theme.barHeight - root.height) / 2 + 11
        visible: root.activeButton !== null
        transformOrigin: Item.Top                    // swings from the thread's top

        Behavior on x {
            SpringAnimation { spring: 3.5; damping: 0.22; epsilon: 0.3 }
        }

        // swing: tilt against the direction it travels, then settle
        property real lastX: x
        onXChanged: {
            const dx = x - lastX;
            lastX = x;
            if (Math.abs(dx) > 0.5) rotation = Math.max(-28, Math.min(28, rotation - dx * 0.9));
        }
        Behavior on rotation {
            SpringAnimation { spring: 4; damping: 0.18; epsilon: 0.2 }
        }
        Timer {
            interval: 120
            running: hanger.rotation !== 0
            repeat: true
            onTriggered: hanger.rotation = 0
        }

        Rectangle {                                  // thread
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1
            height: parent.height - 9
            color: Qt.alpha(Theme.foreground, 0.6)
        }

        Spider {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 12
            height: 12
            color: "#E23636"
        }
    }

    WheelHandler {
        onWheel: event => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${event.angleDelta.y > 0 ? "m-1" : "m+1"}" })`])
    }
}
