import QtQuick
import QtQuick.Layouts
import qs

// Quick-settings button: icon + label (+ optional state line), lit when on.
Rectangle {
    id: tile

    property int glyph: 0
    property string label: ""
    property string detail: ""
    property bool on: false
    property color tint: Theme.accent
    property bool expandable: false      // arrow on the right that opens a list
    property bool expanded: false

    signal clicked
    signal rightClicked
    signal expandClicked

    Layout.fillWidth: true
    implicitHeight: 58
    radius: Theme.radius
    color: on ? Qt.alpha(tint, 0.28) : mouse.containsMouse ? Theme.surface : Qt.alpha(Theme.foreground, 0.05)
    border.color: on ? tint : "transparent"
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: tile.expandable ? 0 : 10
        spacing: 10

        Text {
            text: String.fromCodePoint(tile.glyph)
            color: tile.on ? tile.tint : Theme.dim
            font.family: Theme.font
            font.pixelSize: 20
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: tile.label
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.detail
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
                elide: Text.ElideRight
            }
        }

        // drop-down arrow, its own click target
        Item {
            visible: tile.expandable
            Layout.fillHeight: true
            implicitWidth: 36

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height * 0.5
                color: Qt.alpha(Theme.foreground, 0.15)
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                anchors.leftMargin: 5
                radius: Theme.radius - 4
                color: arrow.containsMouse ? Qt.alpha(Theme.foreground, 0.08) : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(tile.expanded ? 0xF0140 : 0xF0142)
                color: tile.expanded ? tile.tint : Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 3
            }

            MouseArea {
                id: arrow
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.expandClicked()
            }
        }
    }

    MouseArea {
        id: mouse
        z: -1                                // under the arrow
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
    }
}
