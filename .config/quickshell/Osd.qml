import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Networking
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
//   qs ipc call osd keyboard 40               keyboard backlight keys
//   qs ipc call osd toast <kind> <title> <subtitle>   anything else (see `kinds`)
//   qs ipc call osd rich <kind> <title> <subtitle> '<json>'   same, plus any of
//       {"image": "/path.png", "colors": ["#hex", ...],
//        "actions": [{"label": "Open", "glyph": 0xF0770, "cmd": ["xdg-open", "/path"],
//                     "then": ["kind", "title", "subtitle"]}]}
//     (a card with buttons stays 6 s; "then" shows another toast after the click)
// It also pops up by itself for: Bluetooth devices connecting, the charger
// plugged in / out, low battery (stays until you plug in), monitors connected /
// disconnected, Wi-Fi connected / lost / no internet, USB drives and SD cards,
// screen sharing starting / stopping, Bluetooth devices low on battery, a disk
// over 90 % full, and the CPU running too hot.
//   "timeout": ms in the rich json keeps a card up longer (idle lock warning)
//   qs ipc call osd dismissKind <kind>   hides the card only if it's that kind
// Notifications are shown as cards under it (Notifs.qml).
// Hides after ~2.5 s, stays while the pointer is on it. Click the card (or its
// x, or SUPER+Escape: qs ipc call osd hide) to dismiss it right away.
Scope {
    id: root

    property bool shown: false
    property string mode: "media"          // "media", "mic", "brightness", "keyboard" or "toast"
    property int brightness: 0
    property var toast: ({ kind: "", glyph: 0, color: Theme.accent, title: "", subtitle: "", image: "", colors: [], actions: [] })
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
        "calendar": [0xF00F0, Theme.accent],
        "charging": [0xF0084, Theme.battery],
        "on-battery": [0xF06A6, Theme.dim],
        "screenshot": [0xF0E51, Theme.accent],
        "screenshot-off": [0xF01B4, Theme.dim],
        "usb": [0xF129E, Theme.accent],
        "usb-off": [0xF01EA, Theme.dim],
        "monitor": [0xF0379, Theme.accent],
        "monitor-off": [0xF0D90, Theme.dim],
        "wifi": [0xF05A9, Theme.accent],
        "wifi-off": [0xF05AA, Theme.dim],
        "no-internet": [0xF16B5, Theme.urgent],
        "wallpaper": [0xF03D8, Theme.accent],
        "mouse": [0xF037D, Theme.accent],
        "mouse-off": [0xF037E, Theme.dim],
        "layout": [0xF0574, Theme.accent],
        "blur": [0xF00B5, Theme.accent],
        "blur-off": [0xF00B7, Theme.dim],
        "touchpad": [0xF07F8, Theme.accent],
        "touchpad-off": [0xF07F8, Theme.dim],
        "airplane": [0xF001D, Theme.urgent],
        "airplane-off": [0xF001E, Theme.dim],
        "lock": [0xF097F, Theme.accent],
        "share": [0xF1483, Theme.urgent],
        "share-off": [0xF1483, Theme.dim],
        "device-battery": [0xF0083, Theme.urgent],
        "disk": [0xF02CA, Theme.urgent],
        "hot": [0xF10C2, Theme.urgent],
        "done": [0xF05E0, Theme.battery],
        "failed": [0xF0159, Theme.urgent],
        "updated": [0xF03D5, Theme.accent],
        "laptop": [0xF06E7, Theme.dim],
        "laptop-on": [0xF0322, Theme.accent]
    })

    // media mode with something to show: MediaCard instead of the level bar
    readonly property bool mediaCard: mode === "media" && player !== null

    function dismiss() {
        sticky = false;
        shown = false;
    }

    function show() {
        shown = true;
        hideTimer.restart();
    }

    function showToast(kind, title, subtitle, extra) {
        const k = kinds[kind] ?? [0xF009A, Theme.accent];
        const color = kind === "color" && /^#[0-9a-f]{6}$/i.test(title) ? title : k[1];
        const x = extra ?? {};
        toast = { kind: kind, glyph: k[0], color: color, title: title, subtitle: subtitle ?? "",
                  image: x.image ?? "", colors: x.colors ?? [], actions: x.actions ?? [] };
        mode = "toast";
        sticky = kind === "battery-low";
        if (senseKinds.includes(kind)) {
            if (Pack.flag("warningTingle")) sense.restart();
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Sounds.sh", "--error"]);
        }
        hideTimer.interval = x.timeout ?? (toast.actions.length ? 6000 : 2500);
        show();
    }

    // warnings that set off the pack's warning effect (spider-sense: jagged
    // lines flicker out from both sides of the card for a second)
    readonly property var senseKinds: ["battery-low", "hot", "failed", "disk", "no-internet", "device-battery", "share"]

    // "1 h 20 min" from seconds
    function duration(sec) {
        const h = Math.floor(sec / 3600), m = Math.round(sec % 3600 / 60);
        return (h ? h + " h " : "") + m + " min";
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

        function hide(): void {
            root.dismiss();
            Notifs.popups = [];            // pop-ups only, they stay in the panel
        }

        function dismissKind(kind: string): void {
            if (root.mode === "toast" && root.toast.kind === kind) root.dismiss();
        }

        function keyboard(percent: int): void {
            root.brightness = percent;
            root.mode = "keyboard";
            root.show();
        }

        function toast(kind: string, title: string, subtitle: string): void {
            root.showToast(kind, title, subtitle);
        }

        function rich(kind: string, title: string, subtitle: string, extra: string): void {
            let x = {};
            try { x = JSON.parse(extra); } catch (e) { console.warn("osd rich: bad json", extra); }
            root.showToast(kind, title, subtitle, x);
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

    // Bluetooth device connected / disconnected, with its battery if it reports one
    Instantiator {
        model: Bluetooth.devices
        delegate: Connections {
            required property var modelData
            target: modelData
            property bool warned: false
            function onBatteryChanged() {
                const d = modelData, pct = Math.round(d.battery * 100);
                if (!d.connected || !d.batteryAvailable) return;
                if (pct > 20) warned = false;
                else if (pct <= 15 && !warned) {
                    warned = true;
                    root.showToast("device-battery", d.name + " battery low", pct + "% left");
                }
            }
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

    // charger plugged in / out: battery % and time to full / empty
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            const d = UPower.displayDevice;
            const pct = Math.round(d.percentage * 100) + "%";
            if (UPower.onBattery) {
                root.showToast("on-battery", "On battery", pct + (d.timeToEmpty > 0 ? " · " + root.duration(d.timeToEmpty) + " left" : ""));
                return;
            }
            lowBattery.warned = 100;
            root.sticky = false;
            root.showToast("charging", "Charging", pct + (d.timeToFull > 0 ? " · full in " + root.duration(d.timeToFull) : ""));
        }
    }

    // the network / monitor watchers stay quiet for the first seconds after start
    property bool settled: false
    Timer {
        running: true
        interval: 5000
        onTriggered: root.settled = true
    }

    // monitor connected / disconnected, with its size and where it sits
    property var screenNames: Quickshell.screens.map(s => s.name)
    Connections {
        target: Quickshell
        function onScreensChanged() { screenTimer.restart(); }   // wait for the layout to settle
    }
    Timer {
        id: screenTimer
        interval: 1000
        onTriggered: {
            const now = Quickshell.screens;
            const names = now.map(s => s.name);
            const added = now.filter(s => !root.screenNames.includes(s.name));
            const removed = root.screenNames.filter(n => !names.includes(n));
            root.screenNames = names;
            if (added.length) {
                const s = added[0], o = now.find(x => x.name !== s.name);
                const where = !o ? "" : " · " + (s.x < o.x ? "left of " : s.x > o.x ? "right of " : s.y < o.y ? "above " : "below ") + o.name;
                root.showToast("monitor", s.name + " connected", s.width + "×" + s.height + where);
            } else if (removed.length) {
                root.showToast("monitor-off", removed[0] + " disconnected", now.length + " monitor" + (now.length > 1 ? "s" : "") + " left");
            }
        }
    }

    // Wi-Fi network joined / lost, and connected-but-no-internet
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property string ssid: wifiDevice?.networks.values.find(n => n.connected)?.name ?? ""
    property string lastSsid: ""
    onSsidChanged: {
        // airplane mode / Wi-Fi switched off has its own toast
        const radioOn = Networking.wifiEnabled && Networking.wifiHardwareEnabled;
        if (settled && ssid !== "") showToast("wifi", ssid, "Connected");
        else if (settled && lastSsid !== "" && radioOn) showToast("wifi-off", "Wi-Fi disconnected", lastSsid);
        if (ssid !== "") lastSsid = ssid;
    }
    Connections {
        target: Networking
        function onConnectivityChanged() {
            const c = Networking.connectivity;
            if (!root.settled || root.ssid === "") return;
            if (c === NetworkConnectivity.Portal) root.showToast("no-internet", "Sign-in needed", root.ssid + " wants you to log in (browser)");
            else if (c === NetworkConnectivity.Limited || c === NetworkConnectivity.None) root.showToast("no-internet", "No internet", "Connected to " + root.ssid + ", but nothing gets through");
        }
    }

    // screen sharing started / stopped (xdg-desktop-portal-hyprland's video node)
    readonly property bool sharing: Pipewire.nodes.values.some(n => n.type === PwNodeType.VideoSource && /^xdph/.test(n.name))
    onSharingChanged: {
        if (!sharing) { showToast("share-off", "Screen sharing stopped", ""); return; }
        const link = Pipewire.links.values.find(l => /^xdph/.test(l.source?.name ?? ""));
        const app = link?.target?.properties?.["application.name"] ?? "";
        showToast("share", "Sharing your screen", app ? "with " + app : "The red icon in the bar shows while it lasts");
    }

    // disks over 90 % full (each one warned once, until it drops under 85 %),
    // checked every 30 min; CPU over 90 °C, checked every 15 s
    property var diskWarned: ({})
    Process {
        id: diskCheck
        command: ["df", "--output=source,pcent,target", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                for (const line of text.trim().split("\n").slice(1)) {
                    const [src, pcent, target] = line.trim().split(/\s+/);
                    if (seen[src] || target.startsWith("/boot") || target.startsWith("/efi")) continue;
                    seen[src] = true;                       // btrfs: one disk, many mount points
                    const pct = parseInt(pcent);
                    if (pct < 85) delete root.diskWarned[src];
                    else if (pct >= 90 && !root.diskWarned[src]) {
                        root.diskWarned[src] = true;
                        root.showToast("disk", (target === "/" ? "System disk" : target) + " is " + pct + "% full", "Clean the package cache and old logs?", { actions: [
                            { label: "Clean up", glyph: 0xF00E2, cmd: ["kitty", "--class", "updates", "-e", "sh", "-c",
                              "yay -Sc; sudo journalctl --vacuum-size=200M; echo; df -h " + target + "; read -rp 'Done, press Enter' _"] },
                            { label: "Open", glyph: 0xF0770, cmd: ["xdg-open", target] }
                        ] });
                    }
                }
            }
        }
    }
    Timer {
        running: true
        interval: 30 * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: diskCheck.running = true
    }

    property bool hotWarned: false
    Process {
        id: tempCheck
        // CPU package temperature (Intel coretemp / AMD k10temp), in millidegrees
        command: ["sh", "-c", "for h in /sys/class/hwmon/*; do case $(cat $h/name) in coretemp|k10temp|zenpower) cat $h/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = Math.round(parseInt(text) / 1000);
                if (isNaN(c)) return;
                if (c < 80) root.hotWarned = false;
                else if (c >= 90 && !root.hotWarned) {
                    root.hotWarned = true;
                    root.showToast("hot", "CPU is hot: " + c + " °C", "It slows itself down to cool off. Check SUPER+C (btop)");
                }
            }
        }
    }
    Timer {
        running: true
        interval: 15000
        repeat: true
        onTriggered: tempCheck.running = true
    }

    // USB drives and SD cards (scripts/Usb.sh watches UDisks)
    readonly property string usbScript: Quickshell.env("HOME") + "/.config/hypr/scripts/Usb.sh"
    property var drives: ({})            // device -> name, to say which one was removed
    Process {
        running: true
        command: [root.usbScript, "watch"]
        stdout: SplitParser {
            onRead: line => {
                const [what, dev, label, size] = line.split("\t");
                if (what === "add") {
                    const name = label || "USB drive";
                    root.drives[dev] = name;
                    root.showToast("usb", name + " connected", [size, dev].filter(x => x).join(" · "), { actions: [
                        { label: "Open", glyph: 0xF0770, cmd: [root.usbScript, "open", dev] },
                        { label: "Eject", glyph: 0xF01EA, cmd: [root.usbScript, "eject", dev] }
                    ] });
                } else if (what === "remove" && root.drives[dev]) {
                    root.showToast("usb-off", root.drives[dev] + " removed", "Safe to unplug");
                    delete root.drives[dev];
                }
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
        // room on both sides for the spider-sense lines; only the cards take clicks
        implicitWidth: 380 + 2 * 44
        implicitHeight: stack.implicitHeight
        color: "transparent"
        mask: Region { item: stack }

        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay

        // spider-sense: three jagged lines fanning out from each side of the card
        Repeater {
            model: [-1, 1]

            delegate: Canvas {
                id: tingle
                required property int modelData
                readonly property int side: modelData
                x: side < 0 ? 0 : parent.width - 44
                y: 4
                width: 44
                height: 70
                opacity: 0
                scale: 0.6
                transformOrigin: side < 0 ? Item.Right : Item.Left

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = Theme.urgent;
                    ctx.lineWidth = 2.5;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    // each line: zigzag from the card edge outwards, at an angle
                    for (const angle of [-0.55, 0, 0.55]) {
                        const sx = side < 0 ? 42 : 2, sy = 30 + angle * 26;
                        ctx.beginPath();
                        ctx.moveTo(sx, sy);
                        for (let i = 1; i <= 4; i++) {
                            const d = i * 9, zig = (i % 2 ? 4 : -4);
                            ctx.lineTo(sx + side * d, sy + angle * d * 0.9 + zig);
                        }
                        ctx.stroke();
                    }
                }

                Component.onCompleted: requestPaint()
                Connections {
                    target: Theme
                    function onUrgentChanged() { tingle.requestPaint(); }
                }

                SequentialAnimation {
                    running: sense.running
                    loops: 2
                    ParallelAnimation {
                        NumberAnimation { target: tingle; property: "opacity"; from: 0; to: 1; duration: 120 }
                        NumberAnimation { target: tingle; property: "scale"; from: 0.6; to: 1.05; duration: 220; easing.type: Easing.OutBack }
                    }
                    NumberAnimation { target: tingle; property: "opacity"; to: 0; duration: 280 }
                }
            }
        }

        // drives the spider-sense lines (restarted by showToast)
        Timer {
            id: sense
            interval: 1300
        }

        ColumnLayout {
            id: stack
            x: 44
            width: 380
            spacing: Theme.gap

            Rectangle {
                id: card

                Layout.fillWidth: true
                // collapses once faded out so notifications move up
                Layout.preferredHeight: opacity > 0 ? (root.mediaCard ? mediaCard.implicitHeight + 2 * Theme.border : content.implicitHeight + 28) : 0
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

                // media mode: the shared now-playing card (MediaCard.qml) fills the card
                MediaCard {
                    id: mediaCard
                    anchors.fill: parent
                    anchors.margins: Theme.border
                    radius: Theme.radius - Theme.border
                    visible: root.mediaCard
                    player: root.player
                    onUsed: root.show()
                }

                // pack ornament in two corners, like the bar's islands
                Loader {
                    z: 1
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: Theme.border
                    source: Pack.flag("corners") ? Pack.url("Corner.qml") : ""
                    onLoaded: item.corner = 0
                }
                Loader {
                    z: 1
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: Theme.border
                    source: Pack.flag("corners") ? Pack.url("Corner.qml") : ""
                    onLoaded: item.corner = 3
                }

                // click anywhere on the card that isn't a button: dismiss
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: root.dismiss()
                }

                // close button, top right, while the pointer is on the card
                Text {
                    z: 2
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    visible: cardHover.hovered
                    text: String.fromCodePoint(0xF0156)
                    color: closeArea.containsMouse ? Theme.urgent : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 16

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismiss()
                    }
                }

                ColumnLayout {
                    id: content
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 12

                    // ---- toast picture (screenshot, wallpaper) ----
                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 190
                        visible: root.mode === "toast" && root.toast.image !== ""
                        radius: 8
                        color: Theme.surface

                        Image {
                            anchors.fill: parent
                            source: root.toast.image ? "file://" + root.toast.image : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            sourceSize.width: 720
                        }
                    }

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

                    // ---- toast colour strip (new wallpaper's palette) ----
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.mode === "toast" && root.toast.colors.length > 0
                        spacing: 4

                        Repeater {
                            model: root.toast.colors
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 14
                                radius: 4
                                color: modelData
                            }
                        }
                    }

                    // ---- toast buttons ----
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.mode === "toast" && root.toast.actions.length > 0
                        spacing: 8

                        Repeater {
                            model: root.toast.actions
                            delegate: Rectangle {
                                id: action
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 32
                                radius: 8
                                color: actionArea.containsMouse ? Qt.alpha(Theme.accent, 0.35) : Theme.surface

                                Text {
                                    anchors.centerIn: parent
                                    text: (action.modelData.glyph ? String.fromCodePoint(action.modelData.glyph) + "  " : "") + action.modelData.label
                                    color: Theme.foreground
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                }

                                MouseArea {
                                    id: actionArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const a = action.modelData;
                                        Quickshell.execDetached(a.cmd);
                                        if (a.then) root.showToast(a.then[0], a.then[1], a.then[2]);
                                        else root.shown = false;
                                    }
                                }
                            }
                        }
                    }

                    // ---- level bar: volume, or brightness in brightness mode ----
                    RowLayout {
                        id: level
                        visible: root.mode !== "toast" && !root.mediaCard
                        spacing: 12

                        readonly property bool keyboard: root.mode === "keyboard"
                        readonly property bool bright: root.mode === "brightness" || keyboard
                        readonly property bool mic: root.mode === "mic"
                        readonly property bool off: mic ? root.micMuted : !bright && root.muted
                        readonly property int value: bright ? root.brightness : mic ? root.micPercent : root.percent
                        readonly property color tint: off ? Theme.dim : bright ? Theme.brightness : mic ? Theme.mic : Theme.volume

                        Text {
                            text: String.fromCodePoint(level.mic ? (root.micMuted ? 0xF036D : 0xF036C)
                                                       : level.keyboard ? (level.value > 0 ? 0xF030C : 0xF0310)
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
