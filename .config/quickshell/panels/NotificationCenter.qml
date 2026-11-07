import QtQuick
import QtQuick.Layouts
import qs

// Notification history (bell / SUPER+H): newest first, do-not-disturb and clear.
SidePanel {
    name: "notifications"

    Heading {
        text: "Notifications"

        SmallButton {
            text: String.fromCodePoint(Globals.dnd ? 0xF009B : 0xF009A) + "  Do not disturb"
            on: Globals.dnd
            onClicked: Globals.dnd = !Globals.dnd
        }

        SmallButton {
            visible: Notifs.history.length > 0
            text: String.fromCodePoint(0xF05E9) + "  Clear"
            onClicked: Notifs.clearAll()
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.bottomMargin: 20
        visible: Notifs.history.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: String.fromCodePoint(0xF009C) + "\nNo notifications"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        lineHeight: 1.4
    }

    Repeater {
        model: Notifs.history.slice().reverse()

        delegate: NotificationCard {
            required property var modelData
            Layout.fillWidth: true
            notification: modelData
        }
    }
}
