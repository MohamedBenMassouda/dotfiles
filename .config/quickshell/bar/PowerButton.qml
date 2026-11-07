import QtQuick
import Quickshell
import qs

// Opens the power menu (same as CTRL+ALT+P).
Label {
    text: String.fromCodePoint(0xF0425)
    color: mouse.containsMouse ? Theme.urgent : Theme.power

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/UserScripts/PowerMenu.sh"])
    }
}
