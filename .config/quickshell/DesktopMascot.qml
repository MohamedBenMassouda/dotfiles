import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

// The pack's crawler (Spider-Man: a pixel Spider-Man) or mascot lives on empty
// workspaces. It clings under the bar's islands: crawls along one, and at its
// end web-swings across the gap to the next; at the edge of the screen it
// turns around and works its way back to the start, and so on. Hover it (or
// wait, it does it by itself sometimes) and it drops down on a thread, then
// climbs back up. Sits under all windows; only the figure takes the mouse.
// Without island info (bar hidden) it just wanders along the top edge.
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === modelData.name)
    readonly property bool empty: (monitor?.activeWorkspace?.toplevels?.values.length ?? 1) === 0

    visible: empty && Pack.flag("desktopMascot")
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal        // top edge = the islands' bottom edge
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-spider"
    mask: Region { item: spider }

    // the islands he clings to, left to right
    readonly property var spans: (Globals.islands[modelData.name] ?? []).slice().sort((a, b) => a[0] - b[0])
    property int seg: -1                       // island he's on
    property int dir: 1                        // 1 heading right, -1 heading left

    property real drop: 0                      // thread length while hanging
    property bool walking: false
    property bool hanging: false
    property bool swinging: false
    property int facing: 1                     // plain mascot: 1 right, -1 left

    function rand(a, b) { return a + Math.random() * (b - a); }
    function later(ms) { pause.interval = ms; pause.restart(); }

    function walkTo(to) {
        facing = to > spider.x ? 1 : -1;
        walk.to = to;
        walk.duration = Math.abs(to - spider.x) / 55 * 1000;
        walking = true;
        walk.restart();
    }

    function next() {
        if (hanging || swinging) return;
        if (Math.random() < 0.12) { dropDown(); return; }
        if (spans.length === 0) {                       // no bar: wander
            walkTo(rand(20, win.width - spider.width - 20));
            return;
        }
        if (seg < 0 || seg >= spans.length) {           // start on the first island
            seg = 0;
            dir = 1;
            spider.x = spans[0][0] + 6;
        }
        const lo = spans[seg][0] + 6, hi = spans[seg][1] - spider.width - 6;
        const end = dir > 0 ? hi : lo;
        if (Math.abs(spider.x - end) > 2) {
            // crawl to the end of this island, sometimes stopping on the way
            const stop = Math.random() < 0.35 ? spider.x + (end - spider.x) * rand(0.3, 0.7) : end;
            walkTo(stop);
        } else if (seg + dir >= 0 && seg + dir < spans.length) {
            swingTo(seg + dir);
        } else {
            dir = -dir;                                 // edge of the screen: head back
            later(rand(600, 1500));
        }
    }

    // ---- web-swing to the next island: the hand moves on an arc under a
    // point above the gap, starting and ending flush with the islands ----
    readonly property real arc: 58 * Math.PI / 180
    property real hx0: 0
    property real hx1: 0
    property real swingT: 0
    property real handX: 0
    property real handY: 0
    property real swingAngle: 0                // radians, 0 = straight down
    property int target: 0

    function swingTo(n) {
        target = n;
        const w = spider.width;
        hx0 = spider.x + w / 2;
        const xb = dir > 0 ? spans[n][0] + 6 : spans[n][1] - w - 6;
        hx1 = xb + w / 2;
        swinging = true;
        swingT = 0;
        swingAnim.duration = 650 + Math.abs(hx1 - hx0) * 0.7;
        swingAnim.restart();
    }

    readonly property real swingL: Math.max(40, Math.abs(hx1 - hx0) / 2 / Math.sin(arc))
    readonly property real anchorX: (hx0 + hx1) / 2
    readonly property real anchorY: -swingL * Math.cos(arc)

    onSwingTChanged: {
        if (!swinging) return;
        const ease = (1 - Math.cos(Math.PI * swingT)) / 2;
        swingAngle = (-arc + 2 * arc * ease) * Math.sign(hx1 - hx0);
        handX = anchorX + swingL * Math.sin(swingAngle);
        handY = anchorY + swingL * Math.cos(swingAngle);
        spider.x = handX - spider.width * body.attach;
    }

    NumberAnimation {
        id: swingAnim
        target: win
        property: "swingT"
        from: 0
        to: 1
        onFinished: {
            win.swinging = false;
            win.swingAngle = 0;
            win.seg = win.target;
            spider.x = win.hx1 - spider.width / 2;
            win.later(win.rand(500, 1400));
        }
    }

    function dropDown() {
        if (hanging || swinging) return;
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
            win.later(win.spans.length ? win.rand(500, 2200) : win.rand(1200, 4500));
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
            win.later(1500);
        }
    }

    // thread while hanging
    Rectangle {
        x: spider.x + spider.width / 2
        y: 0
        width: 1
        height: win.drop + 4
        visible: win.drop > 0
        color: Qt.alpha(Theme.foreground, 0.55)
    }

    // web line while swinging: from the point above the gap to his hand
    Rectangle {
        x: win.anchorX
        y: win.anchorY
        width: 1.5
        height: win.swingL
        transformOrigin: Item.Top
        rotation: -win.swingAngle * 180 / Math.PI
        visible: win.swinging
        color: Qt.alpha(Theme.foreground, 0.75)
    }

    // a pack crawler figure (pack.json "crawler": poses) or the pack mascot
    // (a head-up drawing, turned to face the way it walks)
    readonly property bool hasCrawler: Pack.on && !!Pack.info.crawler
    property bool stepA: false
    Timer {
        interval: 160
        repeat: true
        running: win.walking && win.hasCrawler
        onTriggered: win.stepA = !win.stepA
    }

    Item {
        id: spider
        x: 60
        y: win.swinging ? win.handY : win.drop
        width: win.hasCrawler ? (body.item?.implicitWidth ?? 28) : 28
        height: win.hasCrawler ? (body.item?.implicitHeight ?? 28) : 28

        HoverHandler {
            id: spiderHover
            onHoveredChanged: if (hovered) win.dropDown()
        }

        Loader {
            id: body
            readonly property real attach: (item && item.attachX !== undefined) ? item.attachX : 0.5
            anchors.fill: parent
            source: !Pack.flag("desktopMascot") ? "" : win.hasCrawler ? Pack.url(Pack.info.crawler) : Pack.url("Mascot.qml")
            // a plain mascot faces the way it walks along the ceiling and points
            // down while hanging or swinging; a crawler figure only sways
            rotation: (win.hasCrawler ? 0 : (win.hanging || win.swinging) ? 180 : win.facing * 90) + wobble
            transform: Rotation {
                origin.x: body.width * body.attach
                origin.y: 0
                angle: win.hasCrawler ? -win.swingAngle * 180 / Math.PI : 0
            }
            property real wobble: 0
            Behavior on rotation {
                enabled: !win.walking
                NumberAnimation { duration: 220 }
            }

            // legs scuttle while walking, a slow sway while hanging
            SequentialAnimation on wobble {
                running: win.hasCrawler ? win.hanging : (win.walking || win.hanging)
                loops: Animation.Infinite
                NumberAnimation { to: win.walking ? 7 : 4; duration: win.walking ? 90 : 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: win.walking ? -7 : -4; duration: win.walking ? 90 : 700; easing.type: Easing.InOutSine }
            }

            Binding {
                target: body.item
                property: "pose"
                value: win.hanging ? "hang" : win.swinging ? "swing" : win.walking ? (win.stepA ? "step1" : "step2") : "cling"
                when: win.hasCrawler && body.item !== null
            }
        }
    }
}
