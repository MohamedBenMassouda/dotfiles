import QtQuick
import qs

// Spider-Man pack desktop crawler: pixel-art Spider-Man in a suit inspired by
// the 2018 game's Advanced Suit (deep navy, big white chest spider, white
// glove and boot trims, large eyes). Drawn for this pack. DesktopMascot.qml
// sets `pose`:
//   "cling"   upside down on the top edge, facing you, arms and legs spread
//   "step1"/"step2"   alternate while crawling along the edge
//   "hang"    hanging by his feet from a thread (dropped down)
//   "swing"   one arm up on a web line (swinging between bar islands)
// attachX: where the web line ties on, 0..1 across (his hand while swinging).
// Each pixel is drawn `px` screen pixels; the size follows the pose.
Canvas {
    id: root

    property string pose: "cling"
    property int px: 2
    readonly property real attachX: pose === "swing" ? 13.5 / 16 : 0.5
    readonly property var rows: poses[pose] ?? poses.cling

    implicitWidth: rows[0].length * px
    implicitHeight: rows.length * px
    antialiasing: false
    onPoseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // R suit main colour, D shading, N second colour, W emblem / glove and boot
    // trims, K black eye rims, E eye lenses. The chosen suit (pack.json "suits",
    // Pack.suit) overrides these.
    readonly property var base: ({ R: "#C8102E", D: "#7A0A1C", B: "#1B2A57", N: "#1B2A57", W: "#F2F2F2", K: "#0D0D10", E: "#FAFAFF" })
    readonly property var colors: Object.assign({}, base, Pack.suitColors)
    onColorsChanged: requestPaint()
    readonly property var poses: ({
        cling: [
            ".RRR.............RRR.",
            "..WW.............WW..",
            "...NN...........NN...",
            ".RR.NN.........NN.RR.",
            ".WW..NNN.NNN.NNN..WW.",
            ".RR...NNNNNNNNN...RR.",
            "..R...RRWWRWWRR...R..",
            "..NN.RRWWWWWWWRR.NN..",
            "...NNRWRWWWWWRWRNN...",
            ".....NRRRRWRRRRN.....",
            ".......RRDRDRR.......",
            "......RKKRRRKKR......",
            ".....RKEEEKEEEKR.....",
            ".....RKEEKRKEEKR.....",
            "......RKKRRRKKR......",
            ".......RRRRRRR.......",
            "........RRRRR........"
        ],
        step1: [
            ".................RRR.",
            ".RRR.............WW..",
            "..WW............NN...",
            "...NN..........NN.RR.",
            ".RR.NNNN.NNN.NNN..WW.",
            ".RR...NNNNNNNNN...RR.",
            "..R...RRWWRWWRR...R..",
            "..NN.RRWWWWWWWRR.NN..",
            "...NNRWRWWWWWRWRNN...",
            ".....NRRRRWRRRRN.....",
            ".......RRDRDRR.......",
            "......RKKRRRKKR......",
            ".....RKEEEKEEEKR.....",
            ".....RKEEKRKEEKR.....",
            "......RKKRRRKKR......",
            ".......RRRRRRR.......",
            "........RRRRR........"
        ],
        step2: [
            ".RRR.............RRR.",
            "..WW.............WW..",
            "...NN...........NN...",
            ".RR.NN.........NN.RR.",
            ".WW..NNN.NNN.NNN.....",
            ".RR...NNNNNNNNN...WW.",
            "..R...RRWWRWWRR...RR.",
            "..NN.RRWWWWWWWRR.NR..",
            "...NNRWRWWWWWRWRNN...",
            ".....NRRRRWRRRRN.....",
            ".......RRDRDRR.......",
            "......RKKRRRKKR......",
            ".....RKEEEKEEEKR.....",
            ".....RKEEKRKEEKR.....",
            "......RKKRRRKKR......",
            ".......RRRRRRR.......",
            "........RRRRR........"
        ],
        swing: [
            ".....RRRRR...RR.",
            "....RRRRRRR..WW.",
            "...RKKRRRKKR.RR.",
            "..RKEEKRKEEKRRR.",
            "..RKEEEKEEEKRRR.",
            "...RKKRRRKKR.RR.",
            "....RRRRRRR..NN.",
            ".....RDRDR...NN.",
            "......RRR....NN.",
            "..NRRRRWRRRRNNN.",
            ".NNRWRWWWRWR....",
            ".NNRRWWWWWRR....",
            ".RN.WRRWRRW.....",
            ".RN.RRWWWRR.....",
            ".RN..RRWRR......",
            ".WW..NNNNN......",
            ".RR..NN.NN......",
            ".....NN.NN......",
            ".....NN.NN......",
            ".....WW.WW......",
            ".....RR.RR......",
            "....RRR.RRR....."
        ],
        hang: [
            "....RRR.RRR....",
            ".....RR.RR.....",
            ".....WW.WW.....",
            ".....NN.NN.....",
            ".....NN.NN.....",
            ".RR..NN.NN..RR.",
            ".WW..NNNNN..WW.",
            ".RN..RRWRR..NR.",
            ".RN.RRWWWRR.NR.",
            ".RN.WRRWRRW.NR.",
            ".NNRRWWWWWRRNN.",
            ".NNRWRWWWRWRNN.",
            "..NRRRRWRRRRN..",
            "......RRR......",
            ".....RDRDR.....",
            "....RRRRRRR....",
            "...RKKRRRKKR...",
            "..RKEEEKEEEKR..",
            "..RKEEKRKEEKR..",
            "...RKKRRRKKR...",
            "....RRRRRRR....",
            ".....RRRRR....."
        ]
    })

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        for (let y = 0; y < rows.length; y++)
            for (let x = 0; x < rows[y].length; x++) {
                const c = rows[y][x];
                if (c === ".") continue;
                ctx.fillStyle = colors[c];
                ctx.fillRect(x * px, y * px, px, px);
            }
    }
}
