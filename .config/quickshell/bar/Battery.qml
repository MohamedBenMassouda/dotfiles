import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Laptop battery: level icon, percentage, charging bolt. Hidden without a battery.
// At 10 % or less on battery, spider-sense lines pulse around it.
Label {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round((dev?.percentage ?? 0) * (dev?.percentage <= 1 ? 100 : 1))
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged

    visible: dev?.isLaptopBattery ?? false
    // battery_10 .. battery_90 are consecutive glyphs starting at U+F007A
    readonly property int level: Math.max(1, Math.min(9, Math.floor(percent / 10)))
    text: String.fromCodePoint(charging ? 0xF0084 : percent >= 95 ? 0xF0079 : 0xF007A + level - 1) + " " + percent + "%"
    color: !charging && percent <= 15 ? Theme.urgent : Theme.battery

    // spider-sense: at 10 % or less (not charging), jagged lines pulse on both sides
    readonly property bool tingling: Pack.flag("warningTingle") && !charging && percent <= 10
    Repeater {
        model: root.tingling ? [-1, 1] : []

        delegate: Canvas {
            id: tingle
            required property int modelData
            width: 8
            height: root.height
            x: modelData < 0 ? -width - 2 : root.width + 2
            onPaint: {
                const ctx = getContext("2d"), side = modelData;
                ctx.reset();
                ctx.strokeStyle = Theme.urgent;
                ctx.lineWidth = 1.5;
                ctx.lineJoin = "round";
                for (const dy of [-5, 0, 5]) {
                    const y = height / 2 + dy, x0 = side < 0 ? width : 0;
                    ctx.beginPath();
                    ctx.moveTo(x0, y);
                    ctx.lineTo(x0 + side * 3, y + dy * 0.3 - 1.5);
                    ctx.lineTo(x0 + side * 6, y + dy * 0.6 + 1.5);
                    ctx.stroke();
                }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.15; duration: 450 }
                NumberAnimation { from: 0.15; to: 1; duration: 450 }
            }
        }
    }
}
