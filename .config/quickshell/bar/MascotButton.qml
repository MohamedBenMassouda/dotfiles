import QtQuick
import Quickshell
import qs

// The pack's mascot at the start of the bar (Pack.qml): click for the app
// launcher (SUPER+D). Hover: it takes the pack colour and wiggles.
Item {
    id: root

    visible: Pack.flag("buttonMascot")
    implicitWidth: 18
    implicitHeight: 18

    Loader {
        id: mascot
        anchors.fill: parent
        source: Pack.url("Mascot.qml")
        rotation: 0
        Binding {
            target: mascot.item
            property: "color"
            value: area.containsMouse ? Pack.color : Theme.accent
            when: mascot.item !== null
        }

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
