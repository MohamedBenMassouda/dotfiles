import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Three floating islands under the top edge of one monitor.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.gap
    exclusiveZone: implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top

    // left: workspaces, cpu/memory, visualiser, open apps
    Island {
        anchors.left: parent.left
        anchors.leftMargin: 8
        y: Theme.gap

        Workspaces { screenName: bar.screen.name }
        SysStats {}
        Cava {}
        Taskbar { screenName: bar.screen.name }
    }

    // centre: clock (hover for calendar)
    Island {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gap

        Notifications {}
        Clock {}
    }

    // right: now playing, app tray, volume + mic, wifi + bluetooth, battery, notifications, power
    Island {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: Theme.gap

        Media {}
        Tray {}
        Volume {}
        Mic {}
        BluetoothStatus {}
        Tray { network: true }
        Battery {}
        PowerButton {}
    }
}
