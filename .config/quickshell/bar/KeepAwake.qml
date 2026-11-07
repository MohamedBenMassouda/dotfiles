import QtQuick
import qs

// Coffee cup: click to stop the screen from locking / sleeping (the bar
// holds an idle inhibitor while it's on, see Bar.qml).
Label {
    text: String.fromCodePoint(Globals.keepAwake ? 0xF0176 : 0xF06CA)
    color: Globals.keepAwake ? Theme.power : Theme.dim

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.keepAwake = !Globals.keepAwake
    }
}
