import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Laptop battery: level icon, percentage, charging bolt. Hidden without a battery.
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
}
