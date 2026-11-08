pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop theme pack: a mascot, corner ornaments, a lock-screen emblem, sounds,
// a few effects and greeting lines, all from packs/<name>/:
//   pack.json     title, colour, which features are on, greeting lines (see packs/spiderman)
//   Mascot.qml    small drawing, facing up, with a `color` property (bar button,
//                 workspace hanger, desktop crawler)
//   Corner.qml    ornament for the top-left corner, with a `corner` property
//                 (0 tl, 1 tr, 2 bl, 3 br: it mirrors itself)
//   Emblem.qml    lock screen picture, with an `open` property (1..0: eyes, if any)
//   sounds/       thwip.wav (screenshots), thwip-soft.wav (notifications),
//                 spider-sense.wav (warnings)
// The chosen pack's name is in ~/.local/state/desktop-pack; "none" is the plain
// desktop, no file means spiderman. Quick settings tile, or: qs ipc call panel pack
// Suits: pack.json "suits" ({name: {title, colors}}) recolour the figures that
// read Pack.suitColors (Spider-Man: Advanced, Classic, Gwen, Miles, Miguel,
// Amazing). The chosen suit is in ~/.local/state/desktop-pack-suit; quick
// settings tile, or: qs ipc call panel suit
// Game mode pauses it (scripts/Pack.sh pause / resume): a flag in the runtime
// dir, so a crash mid-game can't leave it off after the next login.
Singleton {
    id: root

    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/desktop-pack"
    property string name: "spiderman"
    property var info: null                 // pack.json of the chosen pack
    property var available: []              // pack folder names
    readonly property string pauseFile: Quickshell.env("XDG_RUNTIME_DIR") + "/desktop-pack-paused"
    property bool paused: false
    readonly property bool on: name !== "none" && info !== null && !paused
    readonly property string dir: Quickshell.shellPath("packs/" + name)
    readonly property string title: on ? (info.title ?? name) : "None"
    readonly property color color: on && info.color ? info.color : Theme.accent

    readonly property string suitFile: Quickshell.env("HOME") + "/.local/state/desktop-pack-suit"
    property string suitChoice: ""
    readonly property var suits: on ? (info.suits ?? {}) : ({})
    readonly property var suitNames: Object.keys(suits)
    readonly property string suit: suits[suitChoice] ? suitChoice : (on ? (info.suit ?? suitNames[0] ?? "") : "")
    readonly property string suitTitle: suits[suit]?.title ?? suit
    readonly property var suitColors: suits[suit]?.colors ?? ({})
    function nextSuit() {
        if (suitNames.length === 0) return;
        suitChoice = suitNames[(suitNames.indexOf(suit) + 1) % suitNames.length];
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && printf %s "$2" > "$1"', "sh", suitFile, suitChoice]);
    }

    // a feature switch from pack.json ("corners", "warningTingle", ...)
    function flag(key) { return on && info[key] === true; }
    // a file from the pack, as a URL for a Loader / Image ("" when off)
    function url(file) { return on ? "file://" + dir + "/" + file : ""; }

    function set(n) {
        name = n;
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && printf %s "$2" > "$1"', "sh", stateFile, n]);
    }
    // quick settings: none -> each pack -> none
    function next() {
        const all = ["none"].concat(available);
        set(all[(all.indexOf(name) + 1) % all.length]);
    }

    FileView {
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onLoaded: root.name = text().trim() || "spiderman"
        onLoadFailed: root.name = "spiderman"
        onFileChanged: reload()
    }

    FileView {
        path: root.name === "none" ? "" : root.dir + "/pack.json"
        printErrors: false
        onLoaded: {
            try { root.info = JSON.parse(text()); } catch (e) { root.info = null; }
        }
        onLoadFailed: root.info = null
        onPathChanged: if (path === "") root.info = null
    }

    FileView {
        path: root.suitFile
        printErrors: false
        onLoaded: root.suitChoice = text().trim()
    }

    FileView {
        path: root.pauseFile
        printErrors: false
        onLoaded: root.paused = true
        onLoadFailed: root.paused = false
    }

    Process {
        running: true
        command: ["sh", "-c", "for d in \"$1\"/*/; do [ -f \"$d/pack.json\" ] && basename \"$d\"; done", "sh", Quickshell.shellPath("packs")]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.split("\n").filter(s => s)
        }
    }
}
