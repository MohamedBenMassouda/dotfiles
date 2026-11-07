import QtQuick
import QtQuick.Layouts
import qs

// Drop-down list for the login form (users, sessions): the current one is
// marked, click one to pick it.
Rectangle {
    id: picker

    property var items: []
    property int current: 0

    signal picked(int index)

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 320
    implicitHeight: list.implicitHeight + 12
    radius: Theme.radius
    color: Theme.popup
    border.color: Theme.accent
    border.width: Theme.border

    ColumnLayout {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        spacing: 2

        Repeater {
            model: picker.items

            delegate: Rectangle {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius - 4
                color: area.containsMouse ? Theme.surface : index === picker.current ? Qt.alpha(Theme.accent, 0.35) : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: (parent.index === picker.current ? String.fromCodePoint(0xF012C) + "  " : "     ") + parent.modelData
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.picked(parent.index)
                }
            }
        }
    }
}
