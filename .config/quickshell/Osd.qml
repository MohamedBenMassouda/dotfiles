import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs

// Windows-style flyout, top centre under the bar on the focused monitor:
// album art, song, playback buttons and a volume bar. Shown only when asked:
//   qs ipc call osd volume   (Volume.sh: volume keys / mute)
//   qs ipc call osd media    (MediaCtrl.sh: next / previous / play-pause)
//   qs ipc call osd brightness 40   (Brightness.sh: screen brightness keys)
// so songs that change on their own don't pop it up. Hides after ~2.5 s,
// stays while the pointer is on it.
Scope {
    id: root

    property bool shown: false
    property string mode: "media"          // "media" (art + volume) or "brightness"
    property int brightness: 0

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    function show() {
        shown = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    IpcHandler {
        target: "osd"

        function volume(): void {
            root.mode = "media";
            root.show();
        }

        function media(): void {
            root.mode = "media";
            root.show();
        }

        function brightness(percent: int): void {
            root.brightness = percent;
            root.mode = "brightness";
            root.show();
        }
    }

    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: cardHover.hovered ? restart() : root.shown = false
    }

    PanelWindow {
        // stays mapped until the fade-out finishes
        visible: root.shown || card.opacity > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

        anchors.top: true
        margins.top: Theme.gap     // the bar's reserved space already puts this under it
        exclusiveZone: 0
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            id: card

            implicitWidth: 380
            implicitHeight: content.implicitHeight + 28
            radius: Theme.radius
            color: Theme.popup
            border.color: Theme.accent
            border.width: Theme.border

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.96
            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }
            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            HoverHandler {
                id: cardHover
            }

            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                // ---- media: art, title, artist, buttons ----
                RowLayout {
                    visible: root.mode === "media" && root.player !== null
                    spacing: 14

                    ClippingRectangle {
                        implicitWidth: 72
                        implicitHeight: 72
                        radius: 8
                        color: Theme.surface

                        Image {
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 144
                            sourceSize.height: 144
                        }

                        // note when there is no cover
                        Text {
                            anchors.centerIn: parent
                            visible: !(root.player?.trackArtUrl)
                            text: String.fromCodePoint(0xF075A)
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 28
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackTitle || "Nothing playing"
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackArtist ?? ""
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.topMargin: 6
                            spacing: 18

                            Repeater {
                                model: [
                                    { glyph: 0xF04AE, act: () => root.player?.previous() },
                                    { glyph: root.player?.isPlaying ? 0xF03E4 : 0xF040A, act: () => root.player?.togglePlaying() },
                                    { glyph: 0xF04AD, act: () => root.player?.next() }
                                ]

                                delegate: Text {
                                    required property var modelData
                                    text: String.fromCodePoint(modelData.glyph)
                                    color: btn.containsMouse ? Theme.media : Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: 20

                                    MouseArea {
                                        id: btn
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            parent.modelData.act();
                                            root.show();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- level bar: volume, or brightness in brightness mode ----
                RowLayout {
                    id: level
                    spacing: 12

                    readonly property bool bright: root.mode === "brightness"
                    readonly property bool off: !bright && root.muted
                    readonly property int value: bright ? root.brightness : root.percent
                    readonly property color tint: off ? Theme.dim : bright ? Theme.brightness : Theme.volume

                    Text {
                        text: String.fromCodePoint(level.bright ? (level.value > 60 ? 0xF00E0 : level.value > 25 ? 0xF00DF : 0xF00DE)
                                                   : root.muted ? 0xF075F : root.percent > 60 ? 0xF057E : root.percent > 25 ? 0xF0580 : 0xF057F)
                        color: level.tint
                        font.family: Theme.font
                        font.pixelSize: 18
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Theme.surface

                        Rectangle {
                            width: parent.width * Math.min(1, level.value / 100)
                            height: parent.height
                            radius: 3
                            color: level.tint
                            Behavior on width {
                                NumberAnimation { duration: 120 }
                            }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                        text: level.off ? "Muted" : level.value + "%"
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
