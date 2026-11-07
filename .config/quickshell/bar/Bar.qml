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

    // keep-awake (coffee icon / quick settings): no idle lock or sleep while on
    IdleInhibitor {
        window: bar
        enabled: Globals.keepAwake
    }

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

    // right: privacy dots, recording timer, now playing, app tray, volume + mic,
    // bluetooth + wifi, updates, keep-awake, battery, power
    Island {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: Theme.gap

        Privacy {}
        Recording {}
        Media {}
        Tray {}
        Volume {}
        Mic {}
        BluetoothStatus {}
        NetworkStatus {}
        Updates {}
        KeepAwake {}
        Battery {}
        PowerButton {}
    }
}
