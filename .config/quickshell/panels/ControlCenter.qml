import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs
import qs.bar

// Quick settings (Wi-Fi / Bluetooth icons in the bar, SUPER+N):
// toggles, power profile, volume / mic / brightness sliders,
// Wi-Fi networks and Bluetooth devices.
SidePanel {
    id: cc

    name: "control"

    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string userScripts: Quickshell.env("HOME") + "/.config/hypr/UserScripts"

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetworks: wifi ? wifi.networks.values.slice().sort((a, b) => b.connected - a.connected || b.known - a.known || b.signalStrength - a.signalStrength) : []
    readonly property var wifiConnected: wifiNetworks.find(n => n.connected) ?? null

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: adapter ? adapter.devices.values.filter(d => d.paired || d.name).sort((a, b) => b.connected - a.connected || b.paired - a.paired) : []
    readonly property var btConnected: btDevices.find(d => d.connected) ?? null

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    property real brightness: 0
    property string profile: ""
    property bool recording: false
    property var askPassword: null      // secured Wi-Fi network waiting for its password
    property bool wifiOpen: false       // drop-down sections, closed each time the panel opens
    property bool btOpen: false
    property bool phoneOpen: false
    property var btAudio: []            // [{ id, name, active, profiles }] from BtProfile.sh list
    property bool mixerOpen: false

    // apps playing sound, for the mixer
    readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream && n.audio)

    function run(cmd) {
        Quickshell.execDetached(cmd);
    }

    // refresh the things that aren't live every time the panel opens
    onVisibleChanged: {
        if (!visible) {
            askPassword = null;
            wifiOpen = false;
            btOpen = false;
            phoneOpen = false;
            mixerOpen = false;
            if (adapter?.discovering) adapter.discovering = false;
            return;
        }
        readBrightness.running = true;
        readProfile.running = true;
        readRecording.running = true;
    }

    // Wi-Fi scans while the panel is open
    Binding {
        target: cc.wifi
        property: "scannerEnabled"
        value: cc.visible && cc.wifiOpen
        when: cc.wifi !== null
    }

    PwObjectTracker {
        objects: [cc.sink, cc.source].concat(cc.streams)
    }

    Process {
        id: readBrightness
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: cc.brightness = parseInt(text.split(",")[3]) / 100
        }
    }

    // Bluetooth audio profiles, re-read every 2 s while the list is open
    // (they also change by themselves when an app starts using the mic)
    Process {
        id: readBtAudio
        command: [cc.scripts + "/BtProfile.sh", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { cc.btAudio = JSON.parse(text); } catch (e) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: cc.visible && cc.btOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: readBtAudio.running = true
    }

    Process {
        id: readProfile
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: cc.profile = text.trim()
        }
    }

    Process {
        id: readRecording
        command: ["pgrep", "-f", "^gpu-screen-recorder"]
        onExited: code => cc.recording = code === 0
    }

    FileView {
        id: nightState
        path: Quickshell.env("HOME") + "/.cache/.hyprsunset_state"
        watchChanges: true
        onFileChanged: reload()
    }

    // ---- header ----
    Heading {
        text: "Quick settings"

        SmallButton {
            text: String.fromCodePoint(0xF033E) + "  Lock"
            onClicked: {
                Globals.closePanel();
                cc.run(["loginctl", "lock-session"]);
            }
        }

        SmallButton {
            text: String.fromCodePoint(0xF0425) + "  Power"
            onClicked: {
                Globals.closePanel();
                cc.run([cc.userScripts + "/PowerMenu.sh"]);
            }
        }
    }

    // ---- toggles ----
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Tile {
            glyph: Networking.wifiEnabled ? 0xF0928 : 0xF05AA
            label: "Wi-Fi"
            detail: !Networking.wifiEnabled ? "Off" : cc.wifiConnected?.name ?? "Not connected"
            on: Networking.wifiEnabled
            tint: Theme.accent
            expandable: Networking.wifiEnabled
            expanded: cc.wifiOpen
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            onExpandClicked: {
                cc.wifiOpen = !cc.wifiOpen;
                cc.btOpen = false;
            }
        }

        Tile {
            glyph: !(cc.adapter?.enabled) ? 0xF00B2 : cc.btConnected ? 0xF00B1 : 0xF00AF
            label: "Bluetooth"
            detail: !(cc.adapter?.enabled) ? "Off" : cc.btConnected?.name ?? "On"
            on: cc.adapter?.enabled ?? false
            tint: Theme.bluetooth
            expandable: cc.adapter?.enabled ?? false
            expanded: cc.btOpen
            onClicked: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
            onExpandClicked: {
                cc.btOpen = !cc.btOpen;
                cc.wifiOpen = false;
            }
        }

    }

    // ---- Wi-Fi ----
    ColumnLayout {
        Layout.fillWidth: true
        visible: Networking.wifiEnabled && cc.wifi !== null && cc.wifiOpen
        spacing: 2

        Heading {
            text: "Wi-Fi networks"

            SmallButton {
                text: String.fromCodePoint(0xF0493) + "  Settings"
                onClicked: {
                    Globals.closePanel();
                    cc.run(["nm-connection-editor"]);
                }
            }
        }

        Repeater {
            model: cc.wifiNetworks.slice(0, 10)

            delegate: ColumnLayout {
                id: net

                required property var modelData
                readonly property bool secured: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Owe
                readonly property int bars: Math.min(3, Math.floor(modelData.signalStrength * 4))

                Layout.fillWidth: true
                spacing: 4

                MenuRow {
                    Layout.fillWidth: true
                    glyph: String.fromCodePoint([0xF091F, 0xF0922, 0xF0925, 0xF0928][net.bars])
                    label: net.modelData.name
                    dimmed: !net.modelData.connected
                    trailing: net.modelData.stateChanging ? "…"
                              : net.modelData.connected ? "Connected"
                              : net.secured ? String.fromCodePoint(0xF033E) : ""
                    onActivated: {
                        const n = net.modelData;
                        if (n.connected) n.disconnect();
                        else if (n.known || !net.secured) n.connect();
                        else cc.askPassword = cc.askPassword === n ? null : n;
                    }
                }

                // password box for a new secured network
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 34
                    visible: cc.askPassword === net.modelData
                    implicitHeight: 32
                    radius: 6
                    color: Theme.surface
                    border.color: Theme.accent
                    border.width: 1

                    TextInput {
                        id: password
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                        onAccepted: {
                            net.modelData.connectWithPsk(text);
                            cc.askPassword = null;
                        }
                        Keys.onEscapePressed: cc.askPassword = null

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: password.text === ""
                            text: "Password, then Enter"
                            color: Theme.dim
                            font: password.font
                        }
                    }
                }
            }
        }
    }

    // ---- Bluetooth ----
    ColumnLayout {
        Layout.fillWidth: true
        visible: (cc.adapter?.enabled ?? false) && cc.btOpen
        spacing: 2

        Heading {
            text: "Bluetooth devices"

            SmallButton {
                text: String.fromCodePoint(0xF0450) + (cc.adapter?.discovering ? "  Scanning…" : "  Scan")
                on: cc.adapter?.discovering ?? false
                onClicked: cc.adapter.discovering = !cc.adapter.discovering
            }
        }

        Repeater {
            model: cc.btDevices.slice(0, 10)

            delegate: ColumnLayout {
              id: btRow

              required property var modelData
              // audio profiles of this device, if it's a connected headset (BtProfile.sh list)
              readonly property var audio: modelData.connected ? cc.btAudio.find(a => a.name === modelData.name) ?? null : null

              Layout.fillWidth: true
              spacing: 4

              MenuRow {
                readonly property var modelData: btRow.modelData
                Layout.fillWidth: true
                iconSource: Quickshell.iconPath(modelData.icon || "bluetooth", true)
                label: modelData.name
                dimmed: !modelData.connected
                trailing: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting ? "…"
                          : modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%  " : "") + "Connected"
                          : modelData.paired ? "" : "Pair"
                onActivated: {
                    const d = modelData;
                    if (d.connected) d.disconnect();
                    else if (d.paired) d.connect();
                    else {
                        d.trusted = true;
                        d.pair();
                    }
                }
              }

              // audio profile: music (best quality) or calls (mic). Switches back to the
              // best one by itself after a call; this is for choosing by hand.
              Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 34
                Layout.bottomMargin: 4
                visible: btRow.audio !== null
                spacing: 6

                Repeater {
                  model: btRow.audio ? btRow.audio.profiles.slice().sort((a, b) => b.priority - a.priority) : []

                  delegate: SmallButton {
                    required property var modelData
                    readonly property var labels: ({
                        "a2dp-sink": "Music · AAC", "a2dp-sink-sbc_xq": "Music · SBC-XQ", "a2dp-sink-sbc": "Music · SBC",
                        "headset-head-unit": "Calls · mSBC", "headset-head-unit-cvsd": "Calls · CVSD"
                    })
                    text: labels[modelData.name] ?? modelData.description
                    on: btRow.audio.active === modelData.name
                    onClicked: {
                        cc.run([cc.scripts + "/BtProfile.sh", "set", String(btRow.audio.id), modelData.name]);
                        readBtAudio.running = true;
                    }
                  }
                }
              }
            }
        }

        Text {
            visible: cc.btDevices.length === 0
            text: "No devices, press Scan"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Tile {
            glyph: Globals.dnd ? 0xF009B : 0xF009A
            label: "Do not disturb"
            detail: Globals.dnd ? "On" : "Off"
            on: Globals.dnd
            tint: Theme.notifications
            onClicked: Globals.dnd = !Globals.dnd
        }

        Tile {
            glyph: 0xF0594
            label: "Night light"
            detail: on ? "On" : "Off"
            on: nightState.text().trim() === "on"
            tint: Theme.brightness
            onClicked: cc.run([cc.scripts + "/Hyprsunset.sh", "toggle"])
        }

        Tile {
            glyph: Globals.keepAwake ? 0xF0176 : 0xF06CA
            label: "Keep awake"
            detail: Globals.keepAwake ? "No lock or sleep" : "Off"
            on: Globals.keepAwake
            tint: Theme.power
            onClicked: Globals.keepAwake = !Globals.keepAwake
        }

        Tile {
            glyph: 0xF0BCA                  // spider web
            label: "Theme pack"
            detail: Pack.on ? Pack.title : "None, plain desktop"
            on: Pack.on
            tint: Pack.color
            onClicked: Pack.next()
        }

        // the pack's suits (colours of its figures), when it has more than one
        Tile {
            visible: Pack.suitNames.length > 1
            glyph: 0xF0A7B                  // t-shirt: suit
            label: "Suit"
            detail: Pack.suitTitle
            on: true
            tint: Pack.suitColors.R ?? Pack.color
            onClicked: Pack.nextSuit()
        }

        Tile {
            glyph: 0xF03D5
            label: "Updates"
            detail: (Globals.updates > 0 ? Globals.updates + " available" : "Up to date")
                    + (Globals.news > 0 ? " · " + Globals.news + " news to read" : "")
            on: Globals.updates > 0
            tint: Theme.memory
            onClicked: {
                Globals.closePanel();
                Globals.upgrade();
            }
        }

        Tile {
            glyph: 0xF051B
            label: "Focus"
            detail: Globals.focusPhase === "" ? "25 min, no notifications"
                    : (Globals.focusPhase === "work" ? "Focus " : "Break ") + Math.floor(Globals.focusLeft / 60) + ":" + String(Globals.focusLeft % 60).padStart(2, "0")
            on: Globals.focusPhase !== ""
            tint: Theme.notifications
            onClicked: Globals.toggleFocus()
        }

        // phone (KDE Connect): click opens the app, arrow: send file / ring
        Tile {
            glyph: Globals.phone?.charging ? 0xF1397 : 0xF011C
            label: Globals.phone?.name ?? "Phone"
            detail: Globals.phone ? Globals.phone.battery + "%" + (Globals.phone.charging ? " · charging" : "") : "Not connected"
            on: Globals.phone !== null
            tint: Theme.bluetooth
            expandable: Globals.phone !== null
            expanded: cc.phoneOpen
            onClicked: {
                Globals.closePanel();
                cc.run(["kdeconnect-app"]);
            }
            onExpandClicked: cc.phoneOpen = !cc.phoneOpen
        }

        RowLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            visible: cc.phoneOpen && Globals.phone !== null
            spacing: 6

            SmallButton {
                Layout.fillWidth: true
                implicitHeight: 32
                text: String.fromCodePoint(0xF0552) + "  Send file"
                onClicked: {
                    Globals.closePanel();
                    cc.run(["sh", "-c", "f=$(zenity --file-selection --multiple --separator='\n' --title='Send to phone') || exit 0; "
                            + "echo \"$f\" | while read -r x; do kdeconnect-cli -d " + Globals.phone.id + " --share \"$x\"; done"]);
                }
            }

            SmallButton {
                Layout.fillWidth: true
                implicitHeight: 32
                text: String.fromCodePoint(0xF009A) + "  Ring"
                onClicked: Globals.phoneDo(["--ring"])
            }

            SmallButton {
                Layout.fillWidth: true
                implicitHeight: 32
                text: String.fromCodePoint(0xF014C) + "  Send clipboard"
                onClicked: Globals.phoneDo(["--send-clipboard"])
            }
        }

        Tile {
            Layout.columnSpan: 2
            glyph: 0xF044B
            label: "Record screen"
            detail: cc.recording ? "Recording" : "Screen · arrow for area, window, mic, recordings"
            on: cc.recording
            tint: Theme.urgent
            expandable: true
            onExpandClicked: {
                Globals.closePanel();
                cc.run([cc.userScripts + "/RecordMenu.sh"]);
            }
            onClicked: {
                Globals.closePanel();
                cc.run([cc.userScripts + "/ScreenRecord.sh"]);
            }
        }
    }

    // ---- power profile ----
    RowLayout {
        Layout.fillWidth: true
        visible: cc.profile !== ""
        spacing: 6

        Repeater {
            model: [
                { id: "power-saver", glyph: 0xF032A, label: "Saver" },
                { id: "balanced", glyph: 0xF05D1, label: "Balanced" },
                { id: "performance", glyph: 0xF14DE, label: "Performance" }
            ]

            delegate: SmallButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 32
                text: String.fromCodePoint(modelData.glyph) + "  " + modelData.label
                on: cc.profile === modelData.id
                onClicked: {
                    cc.profile = modelData.id;
                    cc.run(["powerprofilesctl", "set", modelData.id]);
                }
            }
        }
    }

    // ---- sliders ----
    LevelSlider {
        Layout.fillWidth: true
        glyph: cc.sink?.audio?.muted ? 0xF0581 : 0xF057E
        value: cc.sink?.audio?.volume ?? 0
        dimmed: cc.sink?.audio?.muted ?? false
        tint: Theme.volume
        onMoved: v => { if (cc.sink?.audio) cc.sink.audio.volume = v; }
        onIconClicked: if (cc.sink?.audio) cc.sink.audio.muted = !cc.sink.audio.muted
    }

    LevelSlider {
        Layout.fillWidth: true
        glyph: cc.source?.audio?.muted ? 0xF036D : 0xF036C
        value: cc.source?.audio?.volume ?? 0
        dimmed: cc.source?.audio?.muted ?? false
        tint: Theme.mic
        onMoved: v => { if (cc.source?.audio) cc.source.audio.volume = v; }
        onIconClicked: if (cc.source?.audio) cc.source.audio.muted = !cc.source.audio.muted
    }

    LevelSlider {
        Layout.fillWidth: true
        glyph: 0xF00DF
        value: cc.brightness
        tint: Theme.brightness
        onMoved: v => {
            cc.brightness = Math.max(0.05, v);
            cc.run(["brightnessctl", "-q", "set", Math.round(cc.brightness * 100) + "%"]);
        }
    }

    // ---- per-app volume ----
    MenuRow {
        Layout.fillWidth: true
        visible: cc.streams.length > 0
        glyph: String.fromCodePoint(cc.mixerOpen ? 0xF0140 : 0xF0142)
        label: "App volume  ·  " + cc.streams.length + (cc.streams.length === 1 ? " app" : " apps")
        dimmed: true
        onActivated: cc.mixerOpen = !cc.mixerOpen
    }

    Repeater {
        model: cc.mixerOpen ? cc.streams : []

        delegate: ColumnLayout {
            id: stream

            required property var modelData
            readonly property string app: modelData.properties["application.name"] || modelData.description || modelData.name

            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.leftMargin: 34
                text: stream.app + (stream.modelData.properties["media.name"] ? "  ·  " + stream.modelData.properties["media.name"] : "")
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            LevelSlider {
                Layout.fillWidth: true
                glyph: stream.modelData.audio.muted ? 0xF0581 : 0xF057E
                value: stream.modelData.audio.volume
                dimmed: stream.modelData.audio.muted
                tint: Theme.volume
                onMoved: v => stream.modelData.audio.volume = v
                onIconClicked: stream.modelData.audio.muted = !stream.modelData.audio.muted
            }
        }
    }
}
