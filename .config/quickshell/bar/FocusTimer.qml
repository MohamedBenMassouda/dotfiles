import QtQuick
import qs

// Focus timer countdown (started from quick settings), hidden when idle.
// Click: stop.
Label {
    visible: Globals.focusPhase !== ""
    text: String.fromCodePoint(Globals.focusPhase === "work" ? 0xF051B : 0xF0176) + " "
          + Math.floor(Globals.focusLeft / 60) + ":" + String(Globals.focusLeft % 60).padStart(2, "0")
    color: Globals.focusPhase === "work" ? Theme.notifications : Theme.power

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.toggleFocus()
    }
}
