pragma Singleton

import QtQuick
import Quickshell

// Shell-wide state shared by the bar, panels and flyouts.
Singleton {
    property bool keepAwake: false       // idle inhibitor (bar coffee icon)
    property bool dnd: false             // do not disturb: no notification popups
    property string panel: ""            // open side panel: "", "control" or "notifications"

    function togglePanel(name) {
        panel = panel === name ? "" : name;
    }
}
