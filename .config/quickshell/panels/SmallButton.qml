import QtQuick
import qs

// Small text/icon button for panel headers ("Clear", "Scan"...).
Rectangle {
    id: btn

    property string text: ""
    property bool on: false

    signal clicked

    implicitWidth: label.implicitWidth + 18
    implicitHeight: 26
    radius: 6
    color: on ? Qt.alpha(Theme.accent, 0.35) : mouse.containsMouse ? Theme.surface : Qt.alpha(Theme.foreground, 0.05)

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
