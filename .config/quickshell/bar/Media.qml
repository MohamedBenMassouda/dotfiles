import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs

// Now playing: the player's app icon (e.g. Spotify) and "title - artist".
// Left click: previous, right click: next, middle click: play/pause,
// scroll: volume. Each one shows the flyout. Hover: now-playing card under it.
Item {
    id: root

    // the player that is playing, else the first one
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string song: player ? [player.trackTitle, player.trackArtist].filter(s => s).join(" - ") : ""
    readonly property string appIcon: player ? (Icons.forApp(player.desktopEntry) || Icons.forApp(player.identity)) : ""

    // the bar shrinks this on narrow screens so the right island never reaches the clock
    property real maxTextWidth: 240
    // width the title takes now (with its spacing), for the bar's sum
    readonly property real textWidth: visible && title.visible ? title.width + row.spacing : 0

    visible: song !== ""
    opacity: player?.isPlaying ? 1 : 0.6
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 6

        // app icon, or a music note if the player has none
        IconImage {
            visible: root.appIcon !== ""
            implicitSize: 16
            source: root.appIcon
        }

        Label {
            visible: root.appIcon === ""
            text: String.fromCodePoint(0xF075A)
            color: Theme.media
        }

        Label {
            id: title
            visible: root.maxTextWidth >= 60
            text: root.song
            color: Theme.media
            elide: Text.ElideRight
            Layout.maximumWidth: root.maxTextWidth
        }

        // pause sign while paused
        Label {
            visible: !(root.player?.isPlaying ?? false)
            text: String.fromCodePoint(0xF03E4)
            color: Theme.dim
        }
    }

    // Hover: a now-playing card drops down under the song (like KDE's media
    // popup) and stays while the pointer is on the song or the card; a short
    // delay lets the pointer travel from one to the other.
    readonly property bool hovered: area.containsMouse || cardHover.hovered
    onHoveredChanged: hovered ? (closeDelay.stop(), popup.visible = true) : closeDelay.restart()

    Timer {
        id: closeDelay
        interval: 300
        onTriggered: popup.visible = false
    }

    PopupWindow {
        id: popup

        visible: false
        color: "transparent"
        implicitWidth: frame.implicitWidth
        implicitHeight: frame.implicitHeight

        // centred under the song, below the bar
        anchor.item: root
        anchor.rect.x: 0
        anchor.rect.y: 0
        anchor.rect.width: root.width
        anchor.rect.height: root.height + 16
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: frame
            implicitWidth: card.implicitWidth + 2 * Theme.border
            implicitHeight: card.implicitHeight + 2 * Theme.border
            radius: Theme.radius
            color: Theme.popup
            border.color: Theme.accent
            border.width: Theme.border

            HoverHandler {
                id: cardHover
            }

            MediaCard {
                id: card
                anchors.fill: parent
                anchors.margins: Theme.border
                radius: Theme.radius - Theme.border
                player: root.player
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: event => {
            if (!root.player) return;
            if (event.button === Qt.LeftButton) root.player.previous();
            else if (event.button === Qt.RightButton) root.player.next();
            else root.player.togglePlaying();          // direct D-Bus call, instant
            Quickshell.execDetached(["qs", "ipc", "call", "osd", "media"]);
        }
        onWheel: wheel => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/Volume.sh",
                                                    wheel.angleDelta.y > 0 ? "--inc" : "--dec"])
    }
}
