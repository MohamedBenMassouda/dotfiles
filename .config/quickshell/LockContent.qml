import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs

// What one monitor shows while locked (lock.qml): blurred wallpaper, clock,
// password box, now playing. `lock` is the root object of lock.qml.
Item {
    id: root

    required property var lock

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    anchors.fill: parent

    // Spider-Man touches off (see Globals.spidey): no mask
    property bool spidey: true
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/spidey-off"
        printErrors: false
        onLoaded: root.spidey = false
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- background ----
    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.config/rofi/.current_wallpaper"
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

    // ---- battery, top right ----
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        visible: UPower.displayDevice.isLaptopBattery
        text: String.fromCodePoint(UPower.onBattery ? 0xF0079 : 0xF0084) + " " + Math.round(UPower.displayDevice.percentage * 100) + "%"
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
    }

    // ---- mask, clock + password ----
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        spacing: 6

        // squints while checking, narrows and shakes on a wrong password, blinks
        Mask {
            id: mask
            visible: root.spidey
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            implicitWidth: 130
            implicitHeight: 160
            open: root.lock.busy ? 0.35 : root.lock.failed ? 0.5 : 1

            transform: Translate { id: maskShake }
            SequentialAnimation {
                id: maskShakeAnim
                loops: 2
                NumberAnimation { target: maskShake; property: "x"; to: -8; duration: 50 }
                NumberAnimation { target: maskShake; property: "x"; to: 8; duration: 80 }
                NumberAnimation { target: maskShake; property: "x"; to: 0; duration: 50 }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.foreground
            font.family: Theme.font
            font.pixelSize: 96
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

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
            implicitWidth: 320
            implicitHeight: 48
            radius: 24
            color: Theme.popup
            border.color: root.lock.failed ? Theme.urgent : input.activeFocus ? Theme.accent : Qt.alpha(Theme.foreground, 0.2)
            border.width: Theme.border

            // shake on a wrong password
            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                loops: 2
                NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 10; duration: 80 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 50 }
            }
            Connections {
                target: root.lock
                function onFailedChanged() {
                    if (!root.lock.failed) return;
                    shakeAnim.restart();
                    maskShakeAnim.restart();
                }
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
                focus: true
                enabled: !root.lock.busy
                onTextChanged: root.lock.failed = false
                onAccepted: {
                    root.lock.tryUnlock(text);
                    text = "";
                }
                Keys.onEscapePressed: text = ""

                Text {
                    anchors.centerIn: parent
                    visible: input.text === ""
                    text: root.lock.busy ? "Checking…" : root.lock.failed ? "Wrong password" : String.fromCodePoint(0xF033E) + "  " + Quickshell.env("USER")
                    color: root.lock.failed ? Theme.urgent : Theme.dim
                    font: input.font
                }
            }
        }

        // PAM messages other than the password prompt (e.g. "account locked for 10 minutes")
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: text !== ""
            text: root.lock.message
            color: Theme.urgent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    // ---- now playing, bottom centre ----
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        visible: root.player !== null && root.player.trackTitle !== ""
        implicitWidth: 380
        implicitHeight: 92
        radius: Theme.radius
        color: Theme.popup
        border.color: Theme.accent
        border.width: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            ClippingRectangle {
                implicitWidth: 68
                implicitHeight: 68
                radius: 8
                color: Theme.surface

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle ?? ""
                    color: Theme.foreground
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist ?? ""
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }

                RowLayout {
                    spacing: 18

                    Repeater {
                        model: [
                            { glyph: 0xF04AE, act: () => root.player?.previous() },
                            { glyph: root.player?.isPlaying ? 0xF03E4 : 0xF040A, act: () => root.player?.togglePlaying() },
                            { glyph: 0xF04AD, act: () => root.player?.next() }
                        ]

                        delegate: Text {
                            required property var modelData
                            text: String.fromCodePoint(modelData.glyph)
                            color: btn.containsMouse ? Theme.media : Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: 20

                            MouseArea {
                                id: btn
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.modelData.act()
                            }
                        }
                    }
                }
            }
        }
    }
}
