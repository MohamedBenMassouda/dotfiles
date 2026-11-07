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

    signal clicked
    signal rightClicked

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
        anchors.rightMargin: 10
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
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
    }
}
