import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

// Spider-tracer: find the mouse pointer. Web lines shoot in from the corners
// and edges of every monitor to the pointer, a ring pulses around it, then it
// all fades (about 1.5 s). The pack's tracer line pops up next to it.
//   qs ipc call tracer fire          (SUPER+ALT+M)
// Takes no clicks, and costs nothing until called.
Scope {
    id: root

    property real gx: 0                    // pointer, global layout coordinates
    property real gy: 0
    property real t: 0                     // 0..1 lines shooting in
    property real fade: 1
    property bool active: false
    property string line: ""

    IpcHandler {
        target: "tracer"
        function fire(): void { where.running = true; }
    }

    Process {
        id: where
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const p = JSON.parse(text);
                    root.gx = p.x;
                    root.gy = p.y;
                } catch (e) { return; }
                root.line = Pack.quip("tracer");
                root.active = true;
                anim.restart();
            }
        }
    }

    SequentialAnimation {
        id: anim
        PropertyAction { target: root; property: "fade"; value: 1 }
        NumberAnimation { target: root; property: "t"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 750 }
        NumberAnimation { target: root; property: "fade"; to: 0; duration: 420 }
        PropertyAction { target: root; property: "active"; value: false }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData
            visible: root.active
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                // clicks go through
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "spider-tracer"

            // pointer in this monitor's coordinates (it may be on another one)
            readonly property real px: root.gx - modelData.x
            readonly property real py: root.gy - modelData.y
            readonly property bool here: px >= 0 && py >= 0 && px <= width && py <= height

            Canvas {
                id: web
                anchors.fill: parent
                opacity: root.fade
                onPaint: {
                    const ctx = getContext("2d"), w = width, h = height;
                    ctx.reset();
                    ctx.strokeStyle = Pack.on ? Pack.suitColors.R ?? Pack.color : Theme.accent;
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";
                    const from = [[0, 0], [w / 2, 0], [w, 0], [w, h / 2], [w, h], [w / 2, h], [0, h], [0, h / 2]];
                    ctx.beginPath();
                    for (const [x, y] of from) {
                        ctx.moveTo(x, y);
                        ctx.lineTo(x + (win.px - x) * root.t, y + (win.py - y) * root.t);
                    }
                    ctx.stroke();
                }
                Connections {
                    target: root
                    function onTChanged() { web.requestPaint(); }
                }
            }

            // ring around the pointer and the line from the pack
            Rectangle {
                visible: win.here && root.t >= 1
                x: win.px - width / 2
                y: win.py - height / 2
                width: 44 + 30 * (1 - root.fade)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 3
                border.color: Pack.on ? Pack.suitColors.R ?? Pack.color : Theme.accent
                opacity: root.fade
            }

            Rectangle {
                visible: win.here && root.t >= 1 && root.line !== ""
                x: Math.min(win.px + 30, win.width - width - 10)
                y: Math.max(10, win.py - 50)
                width: say.implicitWidth + 20
                height: say.implicitHeight + 12
                radius: Theme.radius
                color: Theme.popup
                border.color: Theme.accent
                border.width: Theme.border
                opacity: root.fade

                Text {
                    id: say
                    anchors.centerIn: parent
                    text: root.line
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
            }
        }
    }
}
