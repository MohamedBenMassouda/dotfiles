import QtQuick
import qs

// Spider-Man pack desktop crawler: pixel-art Spider-Man in a suit inspired by
// the 2018 game's Advanced Suit (deep navy, big white chest spider, white
// glove and boot trims, large eyes). Drawn for this pack. DesktopMascot.qml
// sets `pose`:
//   "cling"   upside down on the top edge, facing you, arms and legs spread
//   "step1"/"step2"   alternate while crawling along the edge
//   "hang"    hanging by his feet from a thread (dropped down)
// Each pixel is drawn `px` screen pixels; the size follows the pose.
Canvas {
    id: root

    property string pose: "cling"
    property int px: 2
    readonly property var rows: poses[pose] ?? poses.cling

    implicitWidth: rows[0].length * px
    implicitHeight: rows.length * px
    antialiasing: false
    onPoseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // R red, D dark red, N navy, W white trim / emblem, K black eye rims, E eye white
    readonly property var colors: ({ R: "#C8102E", D: "#7A0A1C", N: "#1B2A57", W: "#F2F2F2", K: "#0D0D10", E: "#FAFAFF" })
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
