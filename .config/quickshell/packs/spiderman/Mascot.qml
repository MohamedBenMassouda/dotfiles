import QtQuick
import qs

// Spider-Man pack mascot: a spider (head, body, eight bent legs), facing up,
// drawn so it scales to any size.
Canvas {
    id: root

    property color color: Pack.color

    implicitWidth: 18
    implicitHeight: 18
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    // right-side legs in a 0..1 box: start (on the body), knee, foot; mirrored for the left
    readonly property var legs: [
        [0.56, 0.40, 0.76, 0.22, 0.80, 0.03],
        [0.58, 0.46, 0.85, 0.36, 0.98, 0.22],
        [0.58, 0.54, 0.85, 0.62, 0.98, 0.80],
        [0.56, 0.60, 0.75, 0.80, 0.79, 0.98]
    ]

    onPaint: {
        const ctx = getContext("2d"), w = width, h = height;
        ctx.reset();
        ctx.fillStyle = color;
        ctx.strokeStyle = color;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.lineWidth = Math.max(1, w * 0.065);

        for (const side of [1, -1]) {
            for (const l of legs) {
                const x = v => (0.5 + side * (v - 0.5)) * w;
                ctx.beginPath();
                ctx.moveTo(x(l[0]), l[1] * h);
                ctx.lineTo(x(l[2]), l[3] * h);
                ctx.lineTo(x(l[4]), l[5] * h);
                ctx.stroke();
            }
        }

        ctx.beginPath();                                   // head
        ctx.ellipse(0.41 * w, 0.27 * h, 0.18 * w, 0.18 * h);
        ctx.fill();
        ctx.beginPath();                                   // body
        ctx.ellipse(0.37 * w, 0.40 * h, 0.26 * w, 0.44 * h);
        ctx.fill();
    }
}
