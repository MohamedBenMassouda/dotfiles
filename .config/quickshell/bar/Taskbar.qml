import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs

// App icons for the windows on this monitor. Click: focus, middle click: close.
RowLayout {
    id: root

    required property string screenName

    spacing: 4

    Repeater {
        model: ToplevelManager.toplevels

        delegate: Rectangle {
            id: app

            required property var modelData
            readonly property string iconSource: Icons.forApp(modelData.appId)
                || Quickshell.iconPath("application-x-executable")

            visible: modelData.screens.some(s => s.name === root.screenName)
            implicitWidth: 28
            implicitHeight: 24
            radius: 6
            color: modelData.activated ? Theme.surface : (mouse.containsMouse ? Qt.alpha(Theme.surface, 0.15) : "transparent")

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: app.iconSource
            }

            // small accent line under the focused app
            Rectangle {
                visible: app.modelData.activated
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 12
                height: 2
                radius: 1
                color: Theme.accent
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => event.button === Qt.MiddleButton ? app.modelData.close() : app.modelData.activate()
            }
        }
    }
}
