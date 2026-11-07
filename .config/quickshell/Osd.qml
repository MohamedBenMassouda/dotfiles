import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs

// Windows-style flyout, top centre under the bar on the focused monitor.
// One card that shows what you just changed:
//   qs ipc call osd volume                    volume keys / mute  (art + volume bar)
//   qs ipc call osd media                     next / previous / play-pause
//   qs ipc call osd mic                       mic level (Volume.sh mic keys, bar scroll)
//   qs ipc call osd brightness 40             screen brightness keys
//   qs ipc call osd toast <kind> <title> <subtitle>   anything else (see `kinds`)
// It also pops up by itself for keyboard layout switches, Bluetooth devices
// connecting, and low battery (that one stays until you plug in).
// Notifications are shown as cards under it (Notifs.qml).
// Hides after ~2.5 s, stays while the pointer is on it.
Scope {
    id: root

    property bool shown: false
    property string mode: "media"          // "media", "mic", "brightness" or "toast"
    property int brightness: 0
    property var toast: ({ glyph: 0, color: Theme.accent, title: "", subtitle: "" })
    property bool sticky: false            // low battery: stays until plugged in

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property int micPercent: Math.round((source?.audio?.volume ?? 0) * 100)

    // icon + colour per toast kind; unknown kinds get a bell
    readonly property var kinds: ({
        "mic-off": [0xF036D, Theme.urgent],
        "mic-on": [0xF036C, Theme.mic],
        "layout": [0xF030C, Theme.accent],
        "caps-on": [0xF030E, Theme.accent],
        "caps-off": [0xF030E, Theme.dim],
        "power-saver": [0xF032A, Theme.battery],
        "balanced": [0xF05D1, Theme.accent],
        "performance": [0xF14DE, Theme.urgent],
        "headphones": [0xF02CB, Theme.bluetooth],
        "headphones-off": [0xF07CE, Theme.dim],
        "bluetooth": [0xF00B1, Theme.bluetooth],
        "bluetooth-off": [0xF00AF, Theme.dim],
        "game": [0xF0297, Theme.cpu],
        "night": [0xF0594, Theme.brightness],
        "night-off": [0xF0599, Theme.dim],
        "record": [0xF044B, Theme.urgent],
        "record-off": [0xF044B, Theme.dim],
        "awake": [0xF0176, Theme.power],
        "awake-off": [0xF06CA, Theme.dim],
        "dnd": [0xF009B, Theme.dim],
        "dnd-off": [0xF009A, Theme.notifications],
        "battery-low": [0xF10CD, Theme.urgent],
        "ocr": [0xF113D, Theme.accent],
        "color": [0xF020A, Theme.accent],     // tinted with the picked colour itself
        "dev": [0xF0868, Theme.accent],
        "focus": [0xF051B, Theme.notifications],
        "phone": [0xF011C, Theme.bluetooth],
        "calendar": [0xF00F0, Theme.accent]
    })

    function show() {
        shown = true;
        hideTimer.restart();
    }

    function showToast(kind, title, subtitle) {
        const k = kinds[kind] ?? [0xF009A, Theme.accent];
        const color = kind === "color" && /^#[0-9a-f]{6}$/i.test(title) ? title : k[1];
        toast = { glyph: k[0], color: color, title: title, subtitle: subtitle ?? "" };
        mode = "toast";
        sticky = kind === "battery-low";
        show();
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
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

        function mic(): void {
            root.mode = "mic";
            root.show();
        }

        function brightness(percent: int): void {
            root.brightness = percent;
            root.mode = "brightness";
            root.show();
        }

        function toast(kind: string, title: string, subtitle: string): void {
            root.showToast(kind, title, subtitle);
        }
    }

    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: cardHover.hovered || root.sticky ? restart() : root.shown = false
    }

    // ---- automatic flyouts ----

    // bar volume / mic modules (scroll, mute click)
    Connections {
        target: Globals
        function onFlyout(kind) {
            root.mode = kind === "mic" ? "mic" : "media";
            root.show();
        }
        function onToast(kind, title, subtitle) {
            root.showToast(kind, title, subtitle);
        }
    }

    // keyboard layout switch (any way: keybind, script, Hyprland itself)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.showToast("layout", "Keyboard layout", event.data.split(",").slice(1).join(","));
        }
    }

    // Bluetooth device connected / disconnected, with its battery if it reports one
    Instantiator {
        model: Bluetooth.devices
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectedChanged() {
                const d = modelData;
                const audio = /audio|headset|headphone/i.test(d.icon);
                const battery = d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "%" : "";
                root.showToast(audio ? (d.connected ? "headphones" : "headphones-off") : (d.connected ? "bluetooth" : "bluetooth-off"),
                               d.name, (d.connected ? "Connected" : "Disconnected") + (d.connected ? battery : ""));
            }
        }
    }

    // low battery: once at 15 %, again at 5 %, stays until plugged in
    Connections {
        id: lowBattery
        target: UPower.displayDevice
        property int warned: 100           // last threshold we warned at

        function onPercentageChanged() {
            const pct = Math.round(UPower.displayDevice.percentage * 100);
            const level = pct <= 5 ? 5 : pct <= 15 ? 15 : 100;
            if (UPower.onBattery && level < lowBattery.warned) {
                lowBattery.warned = level;
                root.showToast("battery-low", "Battery low", pct + "% left, plug in soon");
            }
        }
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (UPower.onBattery) return;
            lowBattery.warned = 100;
            if (root.sticky) {
                root.sticky = false;
                root.shown = false;
            }
        }
    }

    // ---- the window ----

    PanelWindow {
        // stays mapped until the fade-out finishes, or while notifications are up
        visible: root.shown || card.opacity > 0 || Notifs.popups.length > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

        anchors.top: true
        margins.top: Theme.gap     // the bar's reserved space already puts this under it
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: stack.implicitHeight
        color: "transparent"

        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: Theme.gap

            Rectangle {
                id: card

                Layout.fillWidth: true
                // collapses once faded out so notifications move up
                Layout.preferredHeight: opacity > 0 ? content.implicitHeight + 28 : 0
                visible: opacity > 0
                radius: Theme.radius
                color: Theme.popup
                border.color: root.sticky ? Theme.urgent : Theme.accent
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

                    // ---- toast: big icon, title, subtitle ----
                    RowLayout {
                        visible: root.mode === "toast"
                        spacing: 14

                        Text {
                            text: root.toast.glyph ? String.fromCodePoint(root.toast.glyph) : ""
                            color: root.toast.color
                            font.family: Theme.font
                            font.pixelSize: 28
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: root.toast.title
                                color: Theme.foreground
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: root.toast.subtitle
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight
                            }
                        }
                    }

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
                        visible: root.mode !== "toast"
                        spacing: 12

                        readonly property bool bright: root.mode === "brightness"
                        readonly property bool mic: root.mode === "mic"
                        readonly property bool off: mic ? root.micMuted : !bright && root.muted
                        readonly property int value: bright ? root.brightness : mic ? root.micPercent : root.percent
                        readonly property color tint: off ? Theme.dim : bright ? Theme.brightness : mic ? Theme.mic : Theme.volume

                        Text {
                            text: String.fromCodePoint(level.mic ? (root.micMuted ? 0xF036D : 0xF036C)
                                                       : level.bright ? (level.value > 60 ? 0xF00E0 : level.value > 25 ? 0xF00DF : 0xF00DE)
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

            // ---- notifications ----
            Repeater {
                model: Notifs.popups

                delegate: NotificationCard {
                    required property var modelData
                    Layout.fillWidth: true
                    notification: modelData
                    popup: true
                }
            }
        }
    }
}
