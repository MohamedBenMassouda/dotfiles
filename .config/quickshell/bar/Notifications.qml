import QtQuick
import Quickshell
import qs

// Notification bell with the number of notifications.
// Click: notification panel, right click: do not disturb.
Label {
    readonly property int count: Notifs.history.length

    text: Globals.dnd ? String.fromCodePoint(0xF009B)
          : count > 0 ? String.fromCodePoint(0xF116B) + " " + count
          : String.fromCodePoint(0xF009A)
    color: count > 0 && !Globals.dnd ? Theme.notifications : Theme.dim

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? Globals.dnd = !Globals.dnd : Globals.togglePanel("notifications")
    }
}
