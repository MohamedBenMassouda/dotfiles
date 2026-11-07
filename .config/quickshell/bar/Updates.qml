import QtQuick
import qs

// Pending pacman + AUR updates (checked every 30 min in Globals.qml), with a
// "!" while there's Arch news you haven't read (shown when you update).
// Hidden when up to date. Sits in the status pill (click opens quick settings,
// which has the Updates tile); middle click: update right away.
Label {
    visible: Globals.updates > 0
    text: String.fromCodePoint(0xF03D5) + " " + Globals.updates + (Globals.news > 0 ? " !" : "")
    color: Globals.news > 0 ? Theme.urgent : Theme.memory

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: Globals.upgrade()
    }
}
