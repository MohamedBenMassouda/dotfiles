pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon (replaces swaync). Every notification is kept in the
// history (bell panel) and, unless do-not-disturb is on or its app is muted,
// also shown as a flyout under the top-centre card (Osd.qml).
// Critical ones always pop up.
// Muted apps live in notifications.json ({"quiet": ["Spotify"]}), toggled
// from the bell panel.
Singleton {
    id: root

    readonly property list<Notification> history: server.trackedNotifications.values
    property list<Notification> popups: []   // newest first

    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function clearAll() {
        for (const n of history.slice()) n.dismiss();
        popups = [];
    }

    function clearApp(app) {
        for (const n of history.filter(n => appOf(n) === app)) n.dismiss();
    }

    function appOf(n) {
        return n.appName || "Other";
    }

    function isQuiet(app) {
        return settings.quiet.some(q => q.toLowerCase() === app.toLowerCase());
    }

    function toggleQuiet(app) {
        settings.quiet = isQuiet(app) ? settings.quiet.filter(q => q.toLowerCase() !== app.toLowerCase())
                                      : settings.quiet.concat([app]);
        settingsFile.writeAdapter();
    }

    FileView {
        id: settingsFile
        path: Quickshell.shellPath("notifications.json")
        watchChanges: true
        onFileChanged: reload()
        // no file yet: start with the defaults below
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: settings
            property list<string> quiet: ["Spotify"]
        }
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: false

        onNotification: n => {
            n.tracked = !n.transient;
            if (n.urgency !== NotificationUrgency.Critical && (Globals.dnd || root.isQuiet(root.appOf(n)))) return;
            // a replaced notification (same id) is the same object: just move it to the top
            const replaced = root.popups.includes(n);
            root.popups = [n].concat(root.popups.filter(p => p !== n)).slice(0, 4);
            if (!replaced) Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Sounds.sh", "--notify"]);
        }
    }
}
