pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon (replaces swaync). Every notification is kept in the
// history (bell panel) and, unless do-not-disturb is on, also shown as a
// flyout under the top-centre card (Osd.qml). Critical ones ignore DND.
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
            if (Globals.dnd && n.urgency !== NotificationUrgency.Critical) return;
            // a replaced notification (same id) is the same object: just move it to the top
            root.popups = [n].concat(root.popups.filter(p => p !== n)).slice(0, 4);
        }
    }
}
