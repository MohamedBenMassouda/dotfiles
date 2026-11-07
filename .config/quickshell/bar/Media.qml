import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs

// Now playing: the player's app icon (e.g. Spotify) and "title - artist".
// Left click: previous, right click: next, middle click: play/pause,
// scroll: volume. Each one shows the flyout.
Item {
    id: root

    // the player that is playing, else the first one
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string song: player ? [player.trackTitle, player.trackArtist].filter(s => s).join(" - ") : ""
    readonly property string appIcon: player ? (Icons.forApp(player.desktopEntry) || Icons.forApp(player.identity)) : ""

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
            text: root.song
            color: Theme.media
            elide: Text.ElideRight
            Layout.maximumWidth: 240
        }

        // pause sign while paused
        Label {
            visible: !(root.player?.isPlaying ?? false)
            text: String.fromCodePoint(0xF03E4)
            color: Theme.dim
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
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
