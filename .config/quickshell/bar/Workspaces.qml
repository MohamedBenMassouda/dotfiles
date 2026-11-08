import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs

// Kanji workspace numbers: every workspace that exists on any monitor, plus
// the active one. Workspaces living on the other monitor are faded. Click to switch, scroll to move through them.
// The pack's mascot (a spider for Spider-Man) hangs on a thread over the
// active one and swings across when you switch.
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
                onClicked: ws.active ? root.trick()
                                     : Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${ws.number} })`])
            }
        }
    }

    }

    // ---- the spider: hangs on a thread over the active workspace; when you
    // switch it web-swings there: for each workspace on the way it shoots a
    // thread to the top of the island halfway across and swings under it ----
    readonly property real ceiling: -(Theme.barHeight - root.height) / 2      // the island's top edge
    readonly property int activeIndex: (monitor?.activeWorkspace?.id ?? 1) - 1
    // thread length at rest; during a focus session he starts tucked at the top
    // and lowers as the time runs out (a progress bar you can read at a glance)
    readonly property real focusProgress: Globals.focusPhase === "work" && Globals.focusMinutes > 0
                                          ? 1 - Globals.focusLeft / (Globals.focusMinutes * 60) : -1
    readonly property real restLen: focusProgress < 0 ? 10 : 1 + 17 * focusProgress
    readonly property real swingAngle: 55 * Math.PI / 180                 // half the arc of a swing

    function restX(i) {
        const b = buttons.count > i ? buttons.itemAt(i) : null;
        return b ? b.x + b.width - 5 : 0;
    }

    property int lastIndex: activeIndex
    property var path: []           // x of each stop: the old workspace, the ones on the way, the new one
    property real t: 0              // 0 .. path.length - 1 while swinging

    // Hyprland can report a workspace change that isn't one (clicking the
    // workspace you're on blips it for a moment): act only once it settles
    onActiveIndexChanged: settle.restart()
    Timer {
        id: settle
        interval: 40
        onTriggered: root.travel()
    }

    // focus session over: a celebratory flip
    Connections {
        target: Globals
        function onFocusPhaseChanged() { if (Globals.focusPhase === "break") root.trick(); }
    }

    // clicking the workspace you're already on: a flip around the thread instead
    function trick() {
        if (swing.running || flip.running) return;
        flip.restart();
    }
    property real spin: 0
    SequentialAnimation {
        id: flip
        NumberAnimation { target: root; property: "spin"; from: 0; to: 360; duration: 520; easing.type: Easing.InOutQuad }
        PropertyAction { target: root; property: "spin"; value: 0 }
        ScriptAction { script: { root.landing = true; landTimer.restart(); } }
    }

    function travel() {
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
        visible: buttons.count > 0 && Pack.flag("workspaceMascot")
    }

    // the pack's hanger figure (pack.json "hanger", e.g. a pixel Spider-Man with
    // poses), or its mascot. A hanger has `pose` and `attachX` (where the thread
    // ties on); a plain mascot hangs from its top centre.
    readonly property bool hasHanger: Pack.on && !!Pack.info.hanger
    property bool landing: false
    Timer {
        id: landTimer
        interval: 260
        onTriggered: root.landing = false
    }
    Connections {
        target: swing
        function onFinished() {
            root.landing = true;
            landTimer.restart();
        }
    }

    Loader {
        id: hanger
        readonly property real attach: (item && item.attachX !== undefined) ? item.attachX : 0.5
        x: root.pose.sx - width * attach
        y: root.pose.sy - (root.hasHanger ? 0 : 2)
        width: root.hasHanger ? 11 : 12
        height: root.hasHanger ? 15 : 12
        transform: Rotation {
            origin.x: hanger.width * hanger.attach
            origin.y: 0
            angle: -root.pose.angle * 180 / Math.PI + root.spin
        }
        source: !Pack.flag("workspaceMascot") ? "" : root.hasHanger ? Pack.url(Pack.info.hanger) : Pack.url("Mascot.qml")
        visible: buttons.count > 0 && Pack.flag("workspaceMascot")

        Binding {
            target: hanger.item
            property: "pose"
            value: root.path.length >= 2 || flip.running ? "swing" : root.landing ? "land" : "hang"
            when: root.hasHanger && hanger.item !== null
        }
    }

    WheelHandler {
        onWheel: event => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${event.angleDelta.y > 0 ? "m-1" : "m+1"}" })`])
    }
}
