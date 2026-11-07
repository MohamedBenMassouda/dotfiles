import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// Workspace overview (SUPER+A: qs ipc call overview toggle), on the focused
// monitor: every workspace in use plus an empty one, with live-ish previews of
// their windows. Click a window: go to it. Click a workspace: go there.
// Drag a window onto another workspace: move it there. Escape / click
// outside closes.
Scope {
    id: root

    property bool open: false

    IpcHandler {
        target: "overview"
        function toggle(): void {
            root.open = !root.open;
        }
    }

    function hypr(lua) {
        Quickshell.execDetached(["hyprctl", "dispatch", lua]);
    }

    function addr(t) {
        return "address:" + (t.address.startsWith("0x") ? t.address : "0x" + t.address);
    }

    onOpenChanged: if (open) Hyprland.refreshToplevels()   // fresh window positions

    FontLoader {
        id: kanjiFont
        source: "file:///usr/share/fonts/droid/DroidSansJapanese.ttf"
    }

    PanelWindow {
        id: win

        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // workspaces 1-10 that exist, plus the first free one to drop windows on
        readonly property var ids: {
            const used = Hyprland.workspaces.values.map(w => w.id).filter(id => id > 0 && id <= 10).sort((a, b) => a - b);
            const free = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].find(id => !used.includes(id));
            return free ? used.concat([free]).sort((a, b) => a - b) : used;
        }
        readonly property var mon: Hyprland.focusedMonitor
        readonly property real monW: mon ? mon.width / mon.scale : 1920
        readonly property real monH: mon ? mon.height / mon.scale : 1080
        readonly property int columns: Math.min(ids.length, ids.length > 4 ? 4 : ids.length)
        readonly property real cellW: Math.min(420, (width - 120) / Math.max(1, columns) - 24)

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.background, 0.55)

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.open = false
        }

        GridLayout {
            anchors.centerIn: parent
            columns: win.columns
            columnSpacing: 24
            rowSpacing: 24

            Repeater {
                model: win.ids

                delegate: Rectangle {
                    id: cell

                    required property int modelData
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                    readonly property var wsMon: ws?.monitor ?? win.mon
                    readonly property bool current: win.mon?.activeWorkspace?.id === modelData
                    // windows are drawn at the scale of their own monitor
                    readonly property real s: win.cellW / ((wsMon?.width ?? win.monW) / (wsMon?.scale ?? 1))

                    implicitWidth: win.cellW
                    implicitHeight: win.cellW * win.monH / win.monW
                    radius: Theme.radius
                    color: drop.containsDrag ? Qt.alpha(Theme.accent, 0.25) : Theme.popup
                    border.color: current ? Theme.accent : Qt.alpha(Theme.foreground, 0.15)
                    border.width: current ? Theme.border : 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.hypr(`hl.dsp.focus({ workspace = ${cell.modelData} })`);
                            root.open = false;
                        }
                    }

                    DropArea {
                        id: drop
                        anchors.fill: parent
                        onDropped: drag => {
                            const t = drag.source.toplevel;
                            if (t.workspace?.id !== cell.modelData)
                                root.hypr(`hl.dsp.window.move({ window = "${root.addr(t)}", workspace = ${cell.modelData}, follow = false })`);
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"][cell.modelData - 1]
                        color: Qt.alpha(Theme.foreground, 0.12)
                        font.family: kanjiFont.name
                        font.pixelSize: cell.height * 0.5
                    }

                    Repeater {
                        model: Hyprland.toplevels.values.filter(t => t.workspace?.id === cell.modelData)

                        delegate: Rectangle {
                            id: preview

                            required property var modelData
                            readonly property var toplevel: modelData
                            readonly property var ipc: modelData.lastIpcObject
                            readonly property real homeX: ((ipc.at?.[0] ?? 0) - (cell.wsMon?.x ?? 0)) * cell.s
                            readonly property real homeY: ((ipc.at?.[1] ?? 0) - (cell.wsMon?.y ?? 0)) * cell.s

                            x: homeX
                            y: homeY
                            width: Math.max(24, (ipc.size?.[0] ?? 100) * cell.s)
                            height: Math.max(24, (ipc.size?.[1] ?? 100) * cell.s)
                            z: dragArea.drag.active ? 10 : 1
                            radius: 6
                            color: Theme.surface
                            border.color: hover.containsMouse ? Theme.accent : Qt.alpha(Theme.foreground, 0.2)
                            border.width: 1
                            clip: true

                            Drag.active: dragArea.drag.active
                            Drag.source: preview
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2

                            ScreencopyView {
                                anchors.fill: parent
                                anchors.margins: 1
                                captureSource: root.open ? preview.modelData.wayland : null
                                live: false
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Math.min(40, parent.height * 0.4)
                                source: Icons.forApp(preview.modelData.wayland?.appId ?? "")
                                opacity: 0.9
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                drag.target: preview
                                onReleased: {
                                    if (preview.Drag.active) preview.Drag.drop();
                                    preview.x = Qt.binding(() => preview.homeX);
                                    preview.y = Qt.binding(() => preview.homeY);
                                }
                                onClicked: {
                                    root.hypr(`hl.dsp.focus({ window = "${root.addr(preview.modelData)}" })`);
                                    root.open = false;
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }
}
