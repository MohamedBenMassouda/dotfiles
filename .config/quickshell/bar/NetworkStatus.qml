import QtQuick
import Quickshell.Networking
import qs

// Network status: cable, Wi-Fi signal, disconnected or Wi-Fi off.
// Click: quick settings (network list), right click: Wi-Fi on/off.
Label {
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property int bars: network ? Math.min(3, Math.floor(network.signalStrength * 4)) : 0

    text: String.fromCodePoint(wired ? 0xF0318
                               : !Networking.wifiEnabled ? 0xF05AA
                               : network ? [0xF091F, 0xF0922, 0xF0925, 0xF0928][bars]
                               : 0xF092E)
    color: wired || network ? Theme.accent : Theme.dim

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? Networking.wifiEnabled = !Networking.wifiEnabled : Globals.togglePanel("control")
    }
}
