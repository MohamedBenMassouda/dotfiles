import QtQuick
import QtQuick.Layouts
import qs

// Icon + draggable bar + percentage. `value` is 0..1; emits moved(v) while
// dragging or scrolling. Clicking the icon emits iconClicked (e.g. mute).
RowLayout {
    id: slider

    property int glyph: 0
    property real value: 0
    property color tint: Theme.accent
    property bool dimmed: false

    signal moved(real value)
    signal iconClicked

    spacing: 12

    Text {
        Layout.preferredWidth: 22
        text: String.fromCodePoint(slider.glyph)
        color: slider.dimmed ? Theme.dim : slider.tint
        font.family: Theme.font
        font.pixelSize: 18

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: slider.iconClicked()
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 18

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.surface

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, slider.value))
                height: parent.height
                radius: 3
                color: slider.dimmed ? Theme.dim : slider.tint
            }
        }

        // knob
        Rectangle {
            x: track.width * Math.max(0, Math.min(1, slider.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: Theme.foreground
            visible: drag.containsMouse || drag.pressed
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function set(x) { slider.moved(Math.max(0, Math.min(1, x / width))); }
            onPressed: event => set(event.x)
            onPositionChanged: event => { if (pressed) set(event.x); }
            onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Text {
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(slider.value * 100) + "%"
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
}
