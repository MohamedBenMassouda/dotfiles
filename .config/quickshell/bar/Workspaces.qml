import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Kanji workspace numbers: every workspace that exists on any monitor, plus
// the active one. Workspaces living on the other monitor are faded. Click to switch, scroll to move through them.
// A little spider hangs on a thread over the active one and web-swings
// across when you switch.
Item {
    id: root

    required property string screenName
    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screenName)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // "Droid Sans" is one family name for many files (Latin, Thai, Arabic...);
    // load the Japanese one directly so every kanji renders.
    FontLoader {
        id: kanjiFont
        source: "file:///usr/share/fonts/droid/DroidSansJapanese.ttf"
    }

    RowLayout {
    id: row
    spacing: 4

    Repeater {
        id: buttons
        model: 10

        delegate: Rectangle {
            id: ws

            required property int index
            readonly property int number: index + 1
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === number)
            readonly property bool active: root.monitor?.activeWorkspace?.id === number
            readonly property bool onThisMonitor: workspace?.monitor?.name === root.screenName

            visible: active || workspace !== undefined
            opacity: active || onThisMonitor ? 1 : 0.35
            implicitWidth: 26
            implicitHeight: 24
            radius: 6
            color: active ? Theme.accent : (mouse.containsMouse ? Theme.surface : "transparent")

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Label {
                anchors.centerIn: parent
                text: root.kanji[ws.index]
                font.family: kanjiFont.name
                color: ws.workspace?.urgent ? Theme.urgent : (ws.active ? Theme.foreground : Theme.dim)
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${ws.number} })`])
            }
        }
    }

    }

    // ---- the spider: hangs on a thread over the active workspace; when you
    // switch it web-swings there: for each workspace on the way it shoots a
    // thread to the top of the island halfway across and swings under it ----
    readonly property real ceiling: -(Theme.barHeight - root.height) / 2      // the island's top edge
    readonly property int activeIndex: (monitor?.activeWorkspace?.id ?? 1) - 1
    readonly property real restLen: 10                                    // thread length at rest
    readonly property real swingAngle: 55 * Math.PI / 180                 // half the arc of a swing

    function restX(i) {
        const b = buttons.count > i ? buttons.itemAt(i) : null;
        return b ? b.x + b.width - 5 : 0;
    }

    property int lastIndex: activeIndex
    property var path: []           // x of each stop: the old workspace, the ones on the way, the new one
    property real t: 0              // 0 .. path.length - 1 while swinging

    onActiveIndexChanged: {
        const from = lastIndex, to = activeIndex, step = to > from ? 1 : -1;
        lastIndex = to;
        const xs = [];
        for (let i = from; i !== to + step; i += step) {
            const b = buttons.itemAt(i);
            if (b && (b.visible || i === from)) xs.push(restX(i));
        }
        if (xs.length < 2 || from === to) return;
        swing.stop();
        path = xs;
        t = 0;
        swing.to = xs.length - 1;
        swing.duration = 380 * (xs.length - 1);
        swing.start();
    }

    NumberAnimation {
        id: swing
        target: root
        property: "t"
        from: 0
        onFinished: root.path = []
    }

    // where the thread is tied (ax, top) and where the spider is (sx, sy)
    readonly property var pose: {
        const n = path.length;
        if (n < 2) {
            const x = restX(activeIndex);
            return { ax: x, sx: x, sy: ceiling + restLen, angle: 0 };
        }
        const i = Math.min(Math.floor(t), n - 2), f = t - i;
        const x0 = path[i], x1 = path[i + 1], d = x1 - x0;
        const L = Math.max(restLen / Math.cos(swingAngle), Math.abs(d) / 2 / Math.sin(swingAngle));
        const a0 = Math.asin(Math.min(1, Math.abs(d) / 2 / L));
        const ease = (1 - Math.cos(Math.PI * f)) / 2;              // slow at the ends, fast at the bottom
        const angle = (-a0 + 2 * a0 * ease) * Math.sign(d);
        const ax = (x0 + x1) / 2;
        return { ax: ax, sx: ax + L * Math.sin(angle), sy: ceiling + L * Math.cos(angle), angle: angle };
    }

    // thread: from the tie point to the spider
    Rectangle {
        x: root.pose.ax
        y: root.ceiling
        width: 1
        height: Math.hypot(root.pose.sx - root.pose.ax, root.pose.sy - root.ceiling)
        transformOrigin: Item.Top
        rotation: -root.pose.angle * 180 / Math.PI
        color: Qt.alpha(Theme.foreground, 0.6)
        visible: buttons.count > 0
    }

    Spider {
        x: root.pose.sx - width / 2
        y: root.pose.sy - 2
        width: 12
        height: 12
        transformOrigin: Item.Top
        rotation: -root.pose.angle * 180 / Math.PI
        color: "#E23636"
        visible: buttons.count > 0
    }

    WheelHandler {
        onWheel: event => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${event.angleDelta.y > 0 ? "m-1" : "m+1"}" })`])
    }
}
