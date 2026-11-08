import QtQuick

// Spider-Man pack lock emblem: a web-head mask: red head with web lines and two big white eyes. The eyes
// follow `open` (1 = wide, 0 = shut): the lock screen squints them while it
// checks the password, narrows them on a wrong one, and blinks now and then.
Canvas {
    id: root

    property real open: 1
    property color red: "#C1121F"
    property color web: "#4A0A10"

    implicitWidth: 170
    implicitHeight: 210
    onOpenChanged: requestPaint()

    Behavior on open {
        NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
    }

    // blink every few seconds (only while the eyes are fully open)
    Timer {
        interval: 5200
        running: root.visible
        repeat: true
        onTriggered: if (root.open === 1) blink.start()
    }
    SequentialAnimation {
        id: blink
        NumberAnimation { target: root; property: "open"; to: 0.08; duration: 70 }
        NumberAnimation { target: root; property: "open"; to: 1; duration: 110 }
    }

    onPaint: {
        const ctx = getContext("2d"), w = width, h = height;
        ctx.reset();

        // head: round top, cheeks narrowing to the chin
        const head = () => {
            ctx.beginPath();
            ctx.moveTo(w * 0.5, h * 0.02);
            ctx.bezierCurveTo(w * 0.86, h * 0.02, w * 0.99, h * 0.30, w * 0.95, h * 0.52);
            ctx.bezierCurveTo(w * 0.90, h * 0.80, w * 0.68, h * 0.98, w * 0.5, h * 0.99);
            ctx.bezierCurveTo(w * 0.32, h * 0.98, w * 0.10, h * 0.80, w * 0.05, h * 0.52);
            ctx.bezierCurveTo(w * 0.01, h * 0.30, w * 0.14, h * 0.02, w * 0.5, h * 0.02);
            ctx.closePath();
        };
        head();
        ctx.fillStyle = red;
        ctx.fill();

        // web: threads from the centre, rings around it (kept inside the head)
        ctx.save();
        head();
        ctx.clip();
        ctx.strokeStyle = web;
        ctx.lineWidth = Math.max(1, w * 0.009);
        const cx = w * 0.5, cy = h * 0.47;
        ctx.beginPath();
        for (let a = 0; a < 360; a += 30) {
            const r = a * Math.PI / 180;
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(r) * w, cy + Math.sin(r) * h);
        }
        ctx.stroke();
        for (const k of [0.16, 0.32, 0.5, 0.7]) {
            ctx.beginPath();
            for (let a = 0; a <= 360; a += 30) {
                const r = a * Math.PI / 180, mid = (a - 15) * Math.PI / 180;
                const px = cx + Math.cos(r) * w * k, py = cy + Math.sin(r) * h * k;
                if (a === 0) ctx.moveTo(px, py);
                else ctx.quadraticCurveTo(cx + Math.cos(mid) * w * k * 0.86, cy + Math.sin(mid) * h * k * 0.86, px, py);
            }
            ctx.stroke();
        }
        ctx.restore();

        // eyes: pointed at the outside, rounded at the nose; squashed by `open`
        for (const side of [-1, 1]) {
            const x = v => cx + side * v * w;                // v: distance from the middle
            const ey = h * 0.42;
            ctx.save();
            ctx.translate(0, ey);
            ctx.scale(1, Math.max(0.06, open));
            ctx.translate(0, -ey);
            ctx.beginPath();
            ctx.moveTo(x(0.05), h * 0.50);                     // inner corner, by the nose
            ctx.bezierCurveTo(x(0.03), h * 0.36, x(0.22), h * 0.27, x(0.40), h * 0.25);   // top edge
            ctx.bezierCurveTo(x(0.38), h * 0.42, x(0.24), h * 0.53, x(0.05), h * 0.50);   // bottom edge
            ctx.closePath();
            ctx.fillStyle = "#F4F4F4";
            ctx.fill();
            ctx.lineWidth = w * 0.035;
            ctx.strokeStyle = "#111111";
            ctx.stroke();
            ctx.restore();
        }
    }
}
