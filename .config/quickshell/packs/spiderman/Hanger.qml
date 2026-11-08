import QtQuick
import qs

// Spider-Man pack workspace hanger: a pixel-art Spider-Man (11 x 15 pixels,
// drawn for this pack). Workspaces.qml sets `pose`:
//   "hang"   upside down by his feet (at rest)
//   "swing"  one arm up on the thread, legs tucked (between workspaces)
//   "land"   a quick crouch after a swing
// attachX: where the thread ties on, 0..1 across (the hand while swinging,
// the feet otherwise).
Canvas {
    id: root

    property string pose: "hang"
    readonly property real attachX: (pose === "swing" ? 8.5 : 5.5) / 11

    implicitWidth: 11
    implicitHeight: 15
    antialiasing: false
    onPoseChanged: requestPaint()
    onWidthChanged: requestPaint()

    // R suit main colour, D shading, B second colour, E eye lenses, K black.
    // The chosen suit (pack.json "suits", Pack.suit) overrides these.
    readonly property var base: ({ R: "#C8102E", D: "#7A0A1C", B: "#1B2A57", N: "#1B2A57", W: "#F2F2F2", E: "#F5F5F5", K: "#0F0F12" })
    readonly property var colors: Object.assign({}, base, Pack.suitColors)
    onColorsChanged: requestPaint()
    readonly property var poses: ({
        hang: [
            ".....R.....",
            "....RDR....",
            "....B.B....",
            "....B.B....",
            "....BBB....",
            "....RRR....",
            "...BRDRB...",
            "..RBBRBBR..",
            "..R.RDR.R..",
            "..RKRRRKR..",
            "..KEKRKEK..",
            "..RERRRER..",
            "...KRRRK...",
            "..R.RRR.R..",
            "..R.....R.."
        ],
        swing: [
            "........R..",
            "........R..",
            "..RRRRR.R..",
            ".RKRRRKRR..",
            ".KEKRKEKR..",
            ".RERRRERR..",
            "..KRRRK.R..",
            "..BRDRBRR..",
            ".RBBRBBR...",
            ".R.RDR.....",
            "...BBB.....",
            "...B.BB....",
            "..B....B...",
            "..R....R...",
            "..R........"
        ],
        land: [
            ".....R.....",
            ".....R.....",
            "...RRRRR...",
            "..RKRRRKR..",
            "..KEKRKEK..",
            "..RERRRER..",
            "...KRRRK...",
            ".R.BRDRB.R.",
            ".RBBRBBRBR.",
            "...RDRDR...",
            "..BBBBBBB..",
            ".BB.....BB.",
            ".B.......B.",
            "RR.......RR",
            "..........."
        ]
    })

    onPaint: {
        const ctx = getContext("2d"), rows = poses[pose] ?? poses.hang;
        const px = width / 11, py = height / 15;
        ctx.reset();
        for (let y = 0; y < rows.length; y++)
            for (let x = 0; x < rows[y].length; x++) {
                const c = rows[y][x];
                if (c === ".") continue;
                ctx.fillStyle = colors[c];
                ctx.fillRect(Math.floor(x * px), Math.floor(y * py), Math.ceil(px), Math.ceil(py));
            }
    }
}
