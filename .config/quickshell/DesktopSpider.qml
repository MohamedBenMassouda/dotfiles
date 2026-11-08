import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

// A spider that lives on empty workspaces: it crawls along the top edge of the
// screen (just under the bar), stops now and then, and drops down on a thread
// when you hover it (or sometimes by itself), then climbs back up.
// Sits under all windows and only the spider itself takes the mouse.
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === modelData.name)
    readonly property bool empty: (monitor?.activeWorkspace?.toplevels?.values.length ?? 1) === 0

    visible: empty
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal        // starts under the bar, not behind it
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-spider"
    mask: Region { item: spider }

    property real drop: 0                      // thread length while hanging
    property bool walking: false
    property bool hanging: false
    property int facing: 1                     // 1 right, -1 left

    function rand(a, b) { return a + Math.random() * (b - a); }

    // walk to a random spot, or (sometimes) drop down for a look around
    function next() {
        if (hanging) return;
        if (Math.random() < 0.15) { dropDown(); return; }
        const to = rand(20, win.width - spider.width - 20);
        facing = to > spider.x ? 1 : -1;
        walk.to = to;
        walk.duration = Math.abs(to - spider.x) / 55 * 1000;
        walking = true;
        walk.restart();
    }

    function dropDown() {
        if (hanging) return;
        walk.stop();
        walking = false;
        hanging = true;
        down.to = rand(140, 230);
        down.restart();
        hang.restart();
    }

    NumberAnimation {
        id: walk
        target: spider
        property: "x"
        onFinished: {
            win.walking = false;
            pause.interval = win.rand(1200, 4500);
            pause.restart();
        }
    }

    Timer {
        id: pause
        interval: 1500
        running: win.visible
        onTriggered: win.next()
    }

    NumberAnimation {
        id: down
        target: win
        property: "drop"
        duration: 1100
        easing.type: Easing.OutBounce
    }

    // hangs while hovered, then a few more seconds, then climbs back up
    Timer {
        id: hang
        interval: 3000
        onTriggered: spiderHover.hovered ? restart() : up.restart()
    }

    NumberAnimation {
        id: up
        target: win
        property: "drop"
        to: 0
        duration: 1500
        easing.type: Easing.InOutQuad
        onFinished: {
            win.hanging = false;
            pause.interval = 1500;
            pause.restart();
        }
    }

    // thread
    Rectangle {
        x: spider.x + spider.width / 2
        y: 0
        width: 1
        height: win.drop + 4
        visible: win.drop > 0
        color: Qt.alpha(Theme.foreground, 0.55)
    }

    Item {
        id: spider
        x: 60
        y: win.drop
        width: 28
        height: 28

        HoverHandler {
            id: spiderHover
            onHoveredChanged: if (hovered) win.dropDown()
        }

        Spider {
            id: body
            anchors.fill: parent
            color: "#E23636"
            // head-up drawing: walking along the ceiling it faces the way it goes,
            // hanging it points down
            rotation: (win.hanging ? 180 : win.facing * 90) + wobble
            property real wobble: 0
            Behavior on rotation {
                enabled: !win.walking
                NumberAnimation { duration: 220 }
            }

            // legs scuttle while walking, a slow sway while hanging
            SequentialAnimation on wobble {
                running: win.walking || win.hanging
                loops: Animation.Infinite
                NumberAnimation { to: win.walking ? 7 : 4; duration: win.walking ? 90 : 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: win.walking ? -7 : -4; duration: win.walking ? 90 : 700; easing.type: Easing.InOutSine }
            }
        }
    }
}
