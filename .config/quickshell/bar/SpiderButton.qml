import QtQuick
import Quickshell
import qs

// Spider emblem at the start of the bar: click for the app launcher (SUPER+D).
// Hover: it turns the suit red and wiggles.
Item {
    id: root

    visible: Globals.spidey
    implicitWidth: 18
    implicitHeight: 18

    Spider {
        id: spider
        anchors.fill: parent
        color: area.containsMouse ? "#E23636" : Theme.accent
        rotation: 0

        SequentialAnimation on rotation {
            running: area.containsMouse
            loops: 1
            NumberAnimation { to: -12; duration: 70 }
            NumberAnimation { to: 10; duration: 90 }
            NumberAnimation { to: 0; duration: 70 }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c",
            "source ~/.config/hypr/UserScripts/menu-toggle.sh; menu_toggle launcher && rofi -show drun -modi drun,filebrowser,run,window"])
    }
}
