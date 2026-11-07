import QtQuick
import QtQuick.Layouts
import qs

// Section title with optional small buttons on the right (default property).
RowLayout {
    property string text: ""
    default property alias actions: extra.data

    Layout.fillWidth: true

    Text {
        Layout.fillWidth: true
        text: parent.text
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
    }

    RowLayout {
        id: extra
        spacing: 6
    }
}
