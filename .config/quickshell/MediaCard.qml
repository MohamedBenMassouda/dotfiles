import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs

// Now playing: the cover blurred behind everything, cover, title and artist,
// position (click to seek), controls (10 s back / forward, previous, play,
// next), playback speed, and the volume (click or scroll the bar to set it).
// Used by the flyout (Osd.qml) and the bar's hover popup (bar/Media.qml).
Item {
    id: root

    property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    property real radius: Theme.radius
    signal used()                       // a control was clicked

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

    implicitWidth: 380
    implicitHeight: column.implicitHeight + 28

    // "2:58" from seconds
    function clock(sec) {
        const t = Math.max(0, Math.floor(sec || 0));
        return Math.floor(t / 60) + ":" + String(t % 60).padStart(2, "0");
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    // MPRIS doesn't announce the playback position: ask every second while shown
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    // the cover, blurred and darkened, behind everything
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: Theme.border
        radius: Theme.radius - Theme.border
        color: "transparent"
        visible: !!root.player?.trackArtUrl

        Image {
            id: backdropArt
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 240
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: backdropArt
            blurEnabled: true
            blur: 1
            blurMax: 48
            saturation: 0.3
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.background, 0.6)
        }
    }


    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        // cover | title, artist, position, controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ClippingRectangle {
                implicitWidth: 92
                implicitHeight: 92
                radius: 10
                color: Theme.surface

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 184
                    sourceSize.height: 184
                }

                // note when there is no cover
                Text {
                    anchors.centerIn: parent
                    visible: !(root.player?.trackArtUrl)
                    text: String.fromCodePoint(0xF075A)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 28
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Nothing playing"
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

                // track position: elapsed, bar (click to seek), length
                RowLayout {
                    Layout.topMargin: 4
                    Layout.fillWidth: true
                    visible: (root.player?.lengthSupported ?? false) && root.player.length > 0
                    spacing: 8

                    Text {
                        text: root.clock(root.player?.position)
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Item {
                        id: seek
                        Layout.fillWidth: true
                        implicitHeight: 12
                        readonly property real progress: Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.alpha(Theme.foreground, 0.2)

                            Rectangle {
                                width: parent.width * seek.progress
                                height: parent.height
                                radius: 2
                                color: Theme.media
                            }
                        }

                        Rectangle {
                            x: seek.width * seek.progress - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: seekArea.containsMouse ? 12 : 8
                            height: width
                            radius: width / 2
                            color: Theme.foreground
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: root.player?.canSeek ?? false
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                root.player.position = Math.max(0, Math.min(1, mouse.x / seek.width)) * root.player.length;
                                root.used();
                            }
                        }
                    }

                    Text {
                        text: root.clock(root.player?.length)
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 26

                    Repeater {
                        // back / forward 10 s only for players that can seek
                        model: [
                            { glyph: 0xF0D2A, size: 17, on: root.player?.canSeek ?? false, act: () => root.player?.seek(-10) },
                            { glyph: 0xF04AE, size: 20, on: true, act: () => root.player?.previous() },
                            { glyph: root.player?.isPlaying ? 0xF03E4 : 0xF040A, size: 24, on: true, act: () => root.player?.togglePlaying() },
                            { glyph: 0xF04AD, size: 20, on: true, act: () => root.player?.next() },
                            { glyph: 0xF0D71, size: 17, on: root.player?.canSeek ?? false, act: () => root.player?.seek(10) }
                        ]

                        delegate: Text {
                            required property var modelData
                            visible: modelData.on
                            Layout.alignment: Qt.AlignVCenter
                            text: String.fromCodePoint(modelData.glyph)
                            color: btn.containsMouse ? Theme.media : Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: modelData.size

                            MouseArea {
                                id: btn
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    parent.modelData.act();
                                    root.used();
                                }
                            }
                        }
                    }

                    // playback speed: click for the next step, right click back to 1x
                    // (only players that allow it, e.g. YouTube in Firefox, mpv)
                    Rectangle {
                        id: speed
                        readonly property var steps: [0.75, 1, 1.25, 1.5, 2]
                            .filter(r => r >= (root.player?.minRate ?? 1) && r <= (root.player?.maxRate ?? 1))
                        visible: steps.length > 1
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: speedText.implicitWidth + 14
                        implicitHeight: 22
                        radius: 11
                        color: speedArea.containsMouse ? Qt.alpha(Theme.media, 0.35) : Qt.alpha(Theme.foreground, 0.12)

                        Text {
                            id: speedText
                            anchors.centerIn: parent
                            text: (Math.round((root.player?.rate ?? 1) * 100) / 100) + "×"
                            color: (root.player?.rate ?? 1) !== 1 ? Theme.media : Theme.foreground
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: true
                        }

                        MouseArea {
                            id: speedArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const r = root.player.rate, st = speed.steps;
                                root.player.rate = mouse.button === Qt.RightButton ? 1
                                    : st[(st.findIndex(x => x > r + 0.01) + st.length) % st.length] ?? st[0];
                                root.used();
                            }
                        }
                    }
                }
            }
        }


        // volume: click or scroll the bar to change it
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: String.fromCodePoint(root.muted ? 0xF075F : root.percent > 60 ? 0xF057E : root.percent > 25 ? 0xF0580 : 0xF057F)
                color: root.muted ? Theme.dim : Theme.volume
                font.family: Theme.font
                font.pixelSize: 18

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.sink?.audio) root.sink.audio.muted = !root.muted;
                        root.used();
                    }
                }
            }

            Item {
                id: vol
                Layout.fillWidth: true
                implicitHeight: 14

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.surface

                    Rectangle {
                        width: parent.width * Math.min(1, root.percent / 100)
                        height: parent.height
                        radius: 3
                        color: root.muted ? Theme.dim : Theme.volume
                        Behavior on width {
                            NumberAnimation { duration: 120 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function set(x) {
                        if (root.sink?.audio) root.sink.audio.volume = Math.max(0, Math.min(1, x / vol.width));
                        root.used();
                    }
                    onPressed: mouse => set(mouse.x)
                    onPositionChanged: mouse => { if (pressed) set(mouse.x); }
                    onWheel: wheel => {
                        if (root.sink?.audio) root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                        root.used();
                    }
                }
            }

            Text {
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
                text: root.muted ? "Muted" : root.percent + "%"
                color: Theme.foreground
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
