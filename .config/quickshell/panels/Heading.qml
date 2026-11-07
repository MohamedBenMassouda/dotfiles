import QtQuick
import QtQuick.Layouts
import qs

// Section title with optional small buttons on the right (default property).
// collapsible: true makes the title a drop-down toggle (chevron + summary).
RowLayout {
    id: heading

    property string text: ""
    property string summary: ""          // shown dimmed next to the title
    property bool collapsible: false
    property bool expanded: true
    default property alias actions: extra.data

    signal toggled                       // title clicked (collapsible only)

    Layout.fillWidth: true

    Item {
        Layout.fillWidth: true
        implicitHeight: title.implicitHeight + 8

        RowLayout {
            id: title
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                visible: heading.collapsible
                text: String.fromCodePoint(heading.expanded ? 0xF0140 : 0xF0142)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
            }

            Text {
                text: heading.text
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: heading.summary
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: heading.collapsible
            cursorShape: Qt.PointingHandCursor
            onClicked: heading.toggled()
        }
    }

    RowLayout {
        id: extra
        visible: heading.expanded
        spacing: 6
    }
}
