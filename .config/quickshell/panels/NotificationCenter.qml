import QtQuick
import QtQuick.Layouts
import qs

// Notification history (bell / SUPER+H), grouped by app, newest first.
// Each app shows its latest notification; click "+N more" to see the rest.
// Per app: mute its popups (still listed here) or clear it. Do-not-disturb and clear all on top.
SidePanel {
    id: panel

    name: "notifications"

    // apps whose group is expanded; folded again each time the panel opens
    property var expanded: ({})
    onVisibleChanged: if (visible) expanded = {}

    Heading {
        text: "Notifications"

        SmallButton {
            text: String.fromCodePoint(Globals.dnd ? 0xF009B : 0xF009A) + "  Do not disturb"
            on: Globals.dnd
            onClicked: Globals.dnd = !Globals.dnd
        }

        SmallButton {
            visible: Notifs.history.length > 0
            text: String.fromCodePoint(0xF05E9) + "  Clear"
            onClicked: Notifs.clearAll()
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.bottomMargin: 20
        visible: Notifs.history.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: String.fromCodePoint(0xF009C) + "\nNo notifications"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        lineHeight: 1.4
    }

    // grouped by app, the app with the newest notification first
    readonly property var groups: {
        const order = [], byApp = {};
        for (const n of Notifs.history.slice().reverse()) {
            const app = Notifs.appOf(n);
            if (!byApp[app]) { byApp[app] = []; order.push(app); }
            byApp[app].push(n);
        }
        return order.map(app => ({ app: app, items: byApp[app] }));
    }

    Repeater {
        model: groups

        delegate: ColumnLayout {
            id: group

            required property var modelData
            readonly property bool quiet: Notifs.isQuiet(modelData.app)
            readonly property bool open: panel.expanded[modelData.app] === true
            readonly property int more: modelData.items.length - 1

            function toggle() {
                const e = Object.assign({}, panel.expanded);
                e[modelData.app] = !open;
                panel.expanded = e;
            }

            Layout.fillWidth: true
            spacing: 6

            // app header: name, count, mute popups, clear
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: group.modelData.app + "  ·  " + group.modelData.items.length
                          + (group.quiet ? "  " + String.fromCodePoint(0xF009B) : "")
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.bold: true
                    elide: Text.ElideRight
                }

                SmallButton {
                    text: group.quiet ? "Unmute" : "Mute popups"
                    on: group.quiet
                    onClicked: Notifs.toggleQuiet(group.modelData.app)
                }

                SmallButton {
                    text: String.fromCodePoint(0xF0156)
                    onClicked: Notifs.clearApp(group.modelData.app)
                }
            }

            // latest only, or all of them when expanded
            Repeater {
                model: group.open ? group.modelData.items : group.modelData.items.slice(0, 1)

                delegate: NotificationCard {
                    required property var modelData
                    Layout.fillWidth: true
                    notification: modelData
                }
            }

            // "+2 more" / "Show less": a stacked-cards look under the latest one
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: group.open ? 0 : 10
                Layout.rightMargin: group.open ? 0 : 10
                Layout.topMargin: group.open ? 0 : -4
                visible: group.more > 0
                implicitHeight: 26
                radius: Theme.radius - 2
                color: moreArea.containsMouse ? Qt.alpha(Theme.foreground, 0.12) : Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: group.open ? String.fromCodePoint(0xF0143) + "  Show less"
                                     : String.fromCodePoint(0xF0140) + "  " + group.more + " more"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }

                MouseArea {
                    id: moreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: group.toggle()
                }
            }
        }
    }
}
