import QtQuick

// A corner of spider web: threads fanning out from one corner, joined by
// sagging rings. Put it in a corner of a card / island; `corner` picks which:
// 0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right.
Canvas {
    id: root

    property int corner: 0
    property color color: Qt.alpha(Theme.accent, 0.55)

    implicitWidth: 26
    implicitHeight: 26
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    // mirror the drawing (made for top-left) into the chosen corner
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.corner === 1 || root.corner === 3 ? -1 : 1
        yScale: root.corner >= 2 ? -1 : 1
    }

    onPaint: {
        const ctx = getContext("2d"), L = width;
        ctx.reset();
        ctx.strokeStyle = color;
        ctx.lineWidth = 1;
        const rays = [0, 22.5, 45, 67.5, 90].map(a => a * Math.PI / 180);
        const at = (r, a) => [r * Math.cos(a), r * Math.sin(a)];

        ctx.beginPath();
        for (const a of rays) {
            ctx.moveTo(0, 0);
            ctx.lineTo(...at(L, a));
        }
        for (const r of [0.38 * L, 0.66 * L, 0.92 * L]) {
            ctx.moveTo(...at(r, rays[0]));
            for (let i = 1; i < rays.length; i++) {
                const mid = (rays[i - 1] + rays[i]) / 2;
                ctx.quadraticCurveTo(...at(r * 0.82, mid), ...at(r, rays[i]));
            }
        }
        ctx.stroke();
    }
}
