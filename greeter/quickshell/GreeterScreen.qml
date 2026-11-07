import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

// One monitor of the login screen: blurred wallpaper, clock, and (on the main
// monitor) user, password, session and power buttons. Click the user name or
// the session to pick from a list.
PanelWindow {
    id: win

    required property var modelData
    required property var greeter

    // main monitor = the one at the top-left of the layout (x, y smallest)
    readonly property bool main: {
        const s = Quickshell.screens.slice().sort((a, b) => a.x - b.x || a.y - b.y);
        return s.length === 0 || s[0].name === modelData.name;
    }

    // which picker list is open under the form: "", "user" or "session"
    property string picker: ""

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.background

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "greeter"
    WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- background ----
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Quickshell.shellPath("wallpaper")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.15
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.background, 0.35)
    }

    // ---- clock ----
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: win.main ? -130 : 0
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: 120
            font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            color: Theme.foreground
            opacity: 0.8
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 6
        }
    }

    // ---- login form (main monitor only) ----
    ColumnLayout {
        visible: win.main
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 10
        spacing: 12

        // avatar: first letter of the name; click the name for the next user
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 72
            implicitHeight: 72
            radius: 36
            color: Theme.accent
            border.color: Qt.alpha(Theme.foreground, 0.3)
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: (win.greeter.users[win.greeter.userIndex]?.full ?? "?").charAt(0).toUpperCase()
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: 32
                font.bold: true
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: (win.greeter.users[win.greeter.userIndex]?.full ?? "")
                  + (win.greeter.users.length > 1 ? "  " + String.fromCodePoint(0xF0140) : "")
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 4
            font.bold: true

            MouseArea {
                anchors.fill: parent
                enabled: win.greeter.users.length > 1
                cursorShape: Qt.PointingHandCursor
                onClicked: win.picker = win.picker === "user" ? "" : "user"
            }
        }

        Picker {
            visible: win.picker === "user"
            items: win.greeter.users.map(u => u.full)
            current: win.greeter.userIndex
            onPicked: i => {
                win.greeter.userIndex = i;
                win.picker = "";
                input.forceActiveFocus();
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            implicitWidth: 320
            implicitHeight: 48
            radius: 24
            color: Theme.popup
            border.color: win.greeter.failed ? Theme.urgent : input.activeFocus ? Theme.accent : Qt.alpha(Theme.foreground, 0.2)
            border.width: Theme.border

            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                loops: 2
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 10; duration: 80 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
            }
            Connections {
                target: win.greeter
                function onFailedChanged() { if (win.greeter.failed) shakeAnim.restart(); }
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 2
                focus: win.main
                enabled: !win.greeter.busy
                onTextChanged: win.greeter.failed = false
                onAccepted: {
                    win.greeter.login(text);
                    text = "";
                }
                Keys.onEscapePressed: {
                    if (win.picker !== "") win.picker = "";
                    else if (win.greeter.preview) Qt.quit();
                    else text = "";
                }

                Text {
                    anchors.centerIn: parent
                    visible: input.text === ""
                    text: win.greeter.busy ? "Checking…" : win.greeter.failed ? "Wrong password" : "Password"
                    color: win.greeter.failed ? Theme.urgent : Theme.dim
                    font: input.font
                }
            }
        }

        // session: click for the next one
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: String.fromCodePoint(0xF0379) + "  " + (win.greeter.session?.name ?? "No sessions found")
                  + (win.greeter.sessions.length > 1 ? "  " + String.fromCodePoint(0xF0140) : "")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: win.greeter.sessions.length > 1
                cursorShape: Qt.PointingHandCursor
                onClicked: win.picker = win.picker === "session" ? "" : "session"
            }
        }

        Picker {
            visible: win.picker === "session"
            items: win.greeter.sessions.map(x => x.name)
            current: win.greeter.sessionIndex
            onPicked: i => {
                win.greeter.sessionIndex = i;
                win.picker = "";
                input.forceActiveFocus();
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: text !== ""
            text: win.greeter.message
            color: win.greeter.failed ? Theme.urgent : Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    // ---- power, bottom right (main monitor) ----
    Row {
        visible: win.main
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 22

        Repeater {
            model: [
                { glyph: 0xF0709, label: "Restart", cmd: ["systemctl", "reboot"] },
                { glyph: 0xF0425, label: "Shut down", cmd: ["systemctl", "poweroff"] }
            ]

            delegate: Item {
                id: btn
                required property var modelData
                implicitWidth: col.implicitWidth
                implicitHeight: col.implicitHeight

                Column {
                    id: col
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(btn.modelData.glyph)
                        color: power.containsMouse ? Theme.accent : Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: 26
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.label
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                }

                MouseArea {
                    id: power
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.greeter.preview ? (win.greeter.message = "Preview: would " + btn.modelData.label.toLowerCase())
                                                   : Quickshell.execDetached(btn.modelData.cmd)
                }
            }
        }
    }
}
