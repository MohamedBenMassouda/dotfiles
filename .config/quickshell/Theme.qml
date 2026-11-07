pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared look for the bar and the flyout. Colours come from wallust
// (templates/colors-quickshell.json -> colors.json) and update live when the
// wallpaper changes; the values below are a fallback.
Singleton {
    readonly property color background: colors.background
    readonly property color foreground: colors.foreground
    readonly property color accent: colors.accent
    readonly property color urgent: colors.urgent

    // same recipe as rofi: translucent panels over Hyprland blur
    readonly property color panel: Qt.alpha(colors.background, 0.80)
    // popups get no Hyprland blur, so they need to be nearly opaque
    readonly property color popup: Qt.alpha(colors.background, 0.96)
    readonly property color surface: Qt.alpha(colors.surface, 0.25)
    readonly property color dim: Qt.alpha(colors.foreground, 0.55)

    // Each bar item gets its own colour: the wallpaper accent's hue rotated by a
    // fixed amount, at a lightness readable on the dark panels. They follow the
    // wallpaper but stay distinct from each other.
    function tint(shift) {
        const base = Qt.color(colors.accent);
        return Qt.hsla((base.hslHue + shift + 1) % 1, 0.60, 0.74, 1);
    }
    readonly property color cpu: tint(0.32)
    readonly property color memory: tint(0.52)
    readonly property color media: tint(0.16)
    readonly property color volume: tint(0.42)
    readonly property color mic: tint(0.82)
    readonly property color bluetooth: tint(0.93)
    readonly property color battery: tint(0.60)
    readonly property color notifications: tint(0.08)
    readonly property color power: tint(0.27)
    readonly property color brightness: tint(0.22)

    readonly property string font: "JetbrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int radius: 10       // same as Hyprland windows
    readonly property int border: 2
    readonly property int barHeight: 34
    readonly property int gap: 6

    FileView {
        path: Quickshell.shellPath("colors.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: colors
            property string background: "#13111A"
            property string foreground: "#9FBDE9"
            property string surface: "#55729A"
            property string accent: "#554F81"
            property string urgent: "#8E575A"
        }
    }
}
