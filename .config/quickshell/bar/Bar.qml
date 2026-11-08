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

    // keep-awake (coffee icon / quick settings) or anything playing:
    // no idle dim, lock or sleep
    IdleInhibitor {
        window: bar
        enabled: Globals.keepAwake || Globals.mediaPlaying
    }

    // tell the desktop crawler where the islands are (empty while the bar is hidden)
    readonly property var islandSpans: visible ? [[leftIsland.x, leftIsland.x + leftIsland.width], [centre.x, centre.x + centre.width], [right.x, right.x + right.width]] : []
    onIslandSpansChanged: {
        const all = Object.assign({}, Globals.islands);
        all[bar.screen.name] = islandSpans;
        Globals.islands = all;
    }

    // left: pack mascot (app launcher), workspaces, cpu/memory, visualiser, open apps
    Island {
        id: leftIsland
        anchors.left: parent.left
        anchors.leftMargin: 8
        y: Theme.gap

        MascotButton {}
        Workspaces { screenName: bar.screen.name }
        SysStats {}
        Cava {}
        Taskbar { screenName: bar.screen.name }
    }

    // centre: clock (hover for calendar)
    Island {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gap

        Notifications {}
        Clock {}
    }

    // right: privacy dots, recording timer, now playing, app tray, volume + mic,
    // status pill (wifi, bluetooth, updates: opens quick settings), keep-awake, battery, power
    Island {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: Theme.gap

        Privacy {}
        Recording {}
        FocusTimer {}
        Media {
            id: media
            // the title gets what's left between the clock island and the rest of
            // this island (8 = screen margin, 12 = gap kept between the islands).
            // Set from a function, not a binding: the island's width depends on it
            function fit() {
                maxTextWidth = Math.min(240, (bar.width - centre.width) / 2 - 8 - 12
                                             - (right.implicitWidth - textWidth));
            }
            Component.onCompleted: Qt.callLater(fit)
        }
        Connections {
            target: right
            function onImplicitWidthChanged() { Qt.callLater(media.fit) }
        }
        Connections {
            target: centre
            function onWidthChanged() { Qt.callLater(media.fit) }
        }
        Connections {
            target: bar
            function onWidthChanged() { Qt.callLater(media.fit) }
        }
        Tray {}
        Volume {}
        Mic {}
        ControlPill {}
        KeepAwake {}
        Battery {}
        PowerButton {}
    }
}
