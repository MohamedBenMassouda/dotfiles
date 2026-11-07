import QtQuick
import qs

// Pending pacman + AUR updates (checked every 30 min in Globals.qml).
// Hidden when up to date. Click: update in a terminal (yay -Syu).
Label {
    visible: Globals.updates > 0
    text: String.fromCodePoint(0xF03D5) + " " + Globals.updates
    color: Theme.memory

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.upgrade()
    }
}
