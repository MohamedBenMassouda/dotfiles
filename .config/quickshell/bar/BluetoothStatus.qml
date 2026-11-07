import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth: off / on / connected (with count). Click: Bluetooth manager,
// right click: turn Bluetooth on/off.
Label {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property int connected: adapter ? adapter.devices.values.filter(d => d.connected).length : 0

    visible: adapter !== null
    text: String.fromCodePoint(!on ? 0xF00B2 : connected > 0 ? 0xF00B1 : 0xF00AF) + (connected > 1 ? " " + connected : "")
    color: on ? Theme.bluetooth : Theme.dim

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
            } else {
                Quickshell.execDetached(["sh", "-c", "command -v bluetui >/dev/null && kitty --class bluetui -e bluetui || blueman-manager"]);
            }
        }
    }
}
