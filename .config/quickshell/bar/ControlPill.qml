import QtQuick
import QtQuick.Layouts
import qs

// GNOME / macOS style status pill: Wi-Fi, Bluetooth (+ headphone battery),
// phone battery (KDE Connect) and pending updates in one rounded button.
// Click: quick settings.
// Right / middle clicks still reach each icon (Wi-Fi off, Bluetooth off...).
Rectangle {
    id: pill

    implicitWidth: row.implicitWidth + 22
    implicitHeight: Theme.barHeight - 10
    radius: height / 2
    color: Globals.panel === "control" ? Qt.alpha(Theme.accent, 0.35)
         : mouse.containsMouse ? Qt.alpha(Theme.foreground, 0.14)
         : Qt.alpha(Theme.foreground, 0.06)

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10

        NetworkStatus {}
        BluetoothStatus {}

        Label {
            visible: Globals.phone !== null
            text: Globals.phone ? String.fromCodePoint(Globals.phone.charging ? 0xF1397 : 0xF011C) + " " + Globals.phone.battery + "%" : ""
            color: Theme.bluetooth
        }

        Updates {}
    }

    // on top, left button only: other buttons fall through to the icons
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.togglePanel("control")
    }
}
