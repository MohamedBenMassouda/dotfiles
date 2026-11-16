import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Game controller connected: a gamepad icon, with its battery when the
// connection reports one. Click: 8BitDo Ultimate Software (profiles),
// right click: Steam's controller settings. Hidden without a controller.
Item {
    id: root

    readonly property var battery: Globals.controllerBatteries[0] ?? null
    readonly property bool low: battery !== null && battery.percent <= 15
    visible: Globals.controllers.length > 0
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 4

        Label {
            text: String.fromCodePoint(0xF0297)
            color: root.low ? Theme.urgent : Theme.accent
        }

        Label {
            visible: root.battery !== null
            text: (root.battery?.percent ?? 0) + "%"
            color: root.low ? Theme.urgent : Theme.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => Quickshell.execDetached(event.button === Qt.RightButton
            ? ["steam", "steam://settings/controller"]
            : [Quickshell.env("HOME") + "/.config/hypr/UserScripts/8BitDo.sh"])
    }
}
