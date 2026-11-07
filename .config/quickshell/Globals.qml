pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell-wide state shared by the bar, panels and flyouts.
Singleton {
    id: root

    property bool keepAwake: false       // idle inhibitor (bar coffee icon)
    property bool dnd: false             // do not disturb: no notification popups
    property string panel: ""            // open side panel: "", "control" or "notifications"

    property int updates: 0              // pending pacman + AUR updates (bar/Updates.qml)

    // checked once for all bars (two checkupdates at once fight over the db lock)
    function upgrade() {
        upgradeTerm.running = true;
    }

    Process {
        id: checkUpdates
        command: ["sh", "-c", "{ checkupdates; yay -Qua; } 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.updates = parseInt(text.trim()) || 0
        }
    }

    Process {
        id: upgradeTerm
        command: ["kitty", "--class", "updates", "-e", "sh", "-c", "yay -Syu; echo; read -rp 'Done, press Enter to close' _"]
        onExited: checkUpdates.running = true
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkUpdates.running = true
    }

    // ask the top-centre flyout (Osd.qml) to show: "volume" or "mic"
    signal flyout(string kind)

    property string lastClosed: ""
    property double lastClosedAt: 0

    function togglePanel(name) {
        // clicking the bar icon of an open panel first closes it through the
        // focus grab (click outside); don't reopen it right away
        if (panel === "" && lastClosed === name && Date.now() - lastClosedAt < 300) return;
        panel = panel === name ? "" : name;
    }

    function closePanel() {
        if (panel === "") return;
        lastClosed = panel;
        lastClosedAt = Date.now();
        panel = "";
    }
}
