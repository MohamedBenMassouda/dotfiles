import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs

// One notification: icon, app, summary, body, action buttons, close button.
// Click: run its default action (if any), × closes it for good.
// As a popup (popup: true) it hides itself after a few seconds, unless hovered
// or critical; it stays in the bell history either way.
Rectangle {
    id: card

    required property Notification notification
    property bool popup: false

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        const s = notification.image || notification.appIcon;
        if (!s) return Icons.forApp(notification.desktopEntry || notification.appName);
        if (s.startsWith("/")) return "file://" + s;
        if (s.includes("://")) return s;
        return Quickshell.iconPath(s, true) || Icons.forApp(notification.desktopEntry || notification.appName);
    }

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: popup ? Theme.popup : Theme.surface
    border.color: critical ? Theme.urgent : popup ? Theme.accent : "transparent"
    border.width: popup || critical ? Theme.border : 0

    Timer {
        running: card.popup && !card.critical && !hover.hovered
        interval: card.notification.expireTimeout > 0 ? card.notification.expireTimeout : 5000
        onTriggered: Notifs.hidePopup(card.notification)
    }

    // gone from the daemon (closed by the app, or ×): drop the popup too
    Connections {
        target: card.notification
        function onClosed() { Notifs.hidePopup(card.notification); }
    }

    HoverHandler { id: hover }

    // popup: drops in on a web thread from above and bounces, the thread then
    // fades. Only the first time it shows (Notifs.dropped), not each time the
    // popup list around it changes.
    transform: Translate { id: dropIn }

    Rectangle {
        id: thread
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        width: 1.5
        height: card.y + 12 - dropIn.y      // up to the top of the screen area
        color: Qt.alpha(Theme.foreground, 0.7)
        opacity: 0
    }

    SequentialAnimation {
        id: dropAnim
        PropertyAction { target: thread; property: "opacity"; value: 1 }
        NumberAnimation { target: dropIn; property: "y"; from: -90; to: 0; duration: 700; easing.type: Easing.OutBounce }
        PauseAnimation { duration: 450 }
        NumberAnimation { target: thread; property: "opacity"; to: 0; duration: 350 }
    }

    Component.onCompleted: {
        if (!popup || Notifs.dropped[notification.id]) return;
        Notifs.dropped[notification.id] = true;
        dropAnim.start();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            const def = card.notification.actions.find(a => a.identifier === "default");
            if (def) def.invoke();
            else if (card.popup) Notifs.hidePopup(card.notification);
        }
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            visible: card.iconSource !== ""
            implicitWidth: 40
            implicitHeight: 40
            radius: 8
            color: "transparent"

            Image {
                anchors.fill: parent
                source: card.iconSource
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 80
                sourceSize.height: 80
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: card.notification.appName || "Notification"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }

                Text {
                    text: String.fromCodePoint(0xF0156)
                    color: closeArea.containsMouse ? Theme.urgent : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notification.dismiss()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notification.summary
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notification.body
                textFormat: Text.StyledText
                color: Theme.foreground
                opacity: 0.85
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 6
                elide: Text.ElideRight
            }

            // action buttons ("Reply", "Open"...), not the hidden default one
            RowLayout {
                Layout.topMargin: 4
                visible: buttons.count > 0
                spacing: 6

                Repeater {
                    id: buttons
                    model: card.notification.actions.filter(a => a.identifier !== "default" && a.text)

                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: label.implicitWidth + 20
                        implicitHeight: 26
                        radius: 6
                        color: btnArea.containsMouse ? Theme.accent : Theme.surface

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
