pragma Singleton

import QtQuick
import Quickshell

// Shell-wide state shared by the bar, panels and flyouts.
Singleton {
    id: root

    property bool keepAwake: false       // idle inhibitor (bar coffee icon)
    property bool dnd: false             // do not disturb: no notification popups
    property string panel: ""            // open side panel: "", "control" or "notifications"

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
