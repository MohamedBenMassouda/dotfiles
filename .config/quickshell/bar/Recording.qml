import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Red dot + elapsed time while gpu-screen-recorder runs (SUPER+SHIFT+R).
// Click: stop and save.
Label {
    id: root

    property double startedAt: 0          // ms since epoch, 0 = not recording
    property int elapsed: 0               // seconds

    visible: startedAt > 0
    text: String.fromCodePoint(0xF044B) + " " + Math.floor(elapsed / 60) + ":" + String(elapsed % 60).padStart(2, "0")
    color: Theme.urgent

    // is it running, and for how long? (checked every 2 s, cheap)
    Process {
        id: check
        // by full command line: the process name is cut to 15 chars ("gpu-screen-reco")
        command: ["sh", "-c", "pid=$(pgrep -of '^gpu-screen-recorder') && ps -o etimes= -p $pid"]
        stdout: StdioCollector {
            onStreamFinished: {
                const secs = parseInt(text.trim());
                root.startedAt = isNaN(secs) ? 0 : Date.now() - secs * 1000;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    Timer {
        interval: 1000
        running: root.startedAt > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/UserScripts/ScreenRecord.sh"])
    }
}
