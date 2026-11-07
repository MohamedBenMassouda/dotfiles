import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

// Bluetooth: off / on / connected (with count), plus the battery of connected
// headphones. Click: quick settings, middle click: Bluetooth manager,
// right click: turn Bluetooth on/off.
Label {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property int connected: adapter ? adapter.devices.values.filter(d => d.connected).length : 0
    readonly property var headset: adapter?.devices.values.find(d => d.connected && d.batteryAvailable && /audio|headset|headphone/i.test(d.icon)) ?? null

    visible: adapter !== null
    text: String.fromCodePoint(!on ? 0xF00B2 : connected > 0 ? 0xF00B1 : 0xF00AF) + (connected > 1 ? " " + connected : "")
          + (headset ? "  " + String.fromCodePoint(0xF02CB) + " " + Math.round(headset.battery * 100) + "%" : "")
    color: on ? Theme.bluetooth : Theme.dim

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
            } else if (event.button === Qt.LeftButton) {
                Globals.togglePanel("control");
            } else {
                Quickshell.execDetached(["sh", "-c", "command -v bluetui >/dev/null && kitty --class bluetui -e bluetui || blueman-manager"]);
            }
        }
    }
}
