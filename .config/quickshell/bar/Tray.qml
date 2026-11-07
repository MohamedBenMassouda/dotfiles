import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// App tray (Discord, Spotify, Steam...). Left click: open the app,
// right click: its menu. With network: true it shows only the Wi-Fi applet,
// so the bar can place it next to Bluetooth.
RowLayout {
    id: root

    property bool network: false

    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: IconImage {
            id: icon

            required property var modelData

            visible: /nm-applet|network/i.test(modelData.id) === root.network
            implicitSize: 18
            source: modelData.icon

            // themed menu (TrayMenu.qml) instead of Qt's default one
            TrayMenu {
                id: menu
                handle: icon.modelData.menu
                anchorItem: icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    if (event.button === Qt.RightButton || icon.modelData.onlyMenu) {
                        if (icon.modelData.hasMenu) menu.open();
                    } else {
                        icon.modelData.activate();
                    }
                }
            }
        }
    }
}
