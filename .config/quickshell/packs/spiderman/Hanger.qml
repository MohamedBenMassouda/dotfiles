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

    // R suit red, D shading, B suit blue, W eye white, K black
    readonly property var colors: ({ R: "#D3202A", D: "#8C121A", B: "#2347A8", W: "#F5F5F5", K: "#0F0F12" })
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
            "..KWKRKWK..",
            "..RWRRRWR..",
            "...KRRRK...",
            "..R.RRR.R..",
            "..R.....R.."
        ],
        swing: [
            "........R..",
            "........R..",
            "..RRRRR.R..",
            ".RKRRRKRR..",
            ".KWKRKWKR..",
            ".RWRRRWRR..",
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
            "..KWKRKWK..",
            "..RWRRRWR..",
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
