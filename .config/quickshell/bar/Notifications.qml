import QtQuick
import Quickshell
import Quickshell.Io
import qs

// swaync status. Click: notification panel, right click: do not disturb.
Label {
    id: root

    property int count: 0
    property bool dnd: false

    text: dnd ? String.fromCodePoint(0xF009B)
              : count > 0 ? String.fromCodePoint(0xF116B) + " " + count
              : String.fromCodePoint(0xF009A)
    color: count > 0 && !dnd ? Theme.notifications : Theme.dim

    // swaync prints one JSON line per change: {"count":2,"dnd":false,...}
    Process {
        running: true
        command: ["swaync-client", "-s"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const s = JSON.parse(data);
                    root.count = s.count;
                    root.dnd = s.dnd;
                } catch (e) {}
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => Quickshell.execDetached(["swaync-client", event.button === Qt.RightButton ? "-d" : "-t", "-sw"])
    }
}
