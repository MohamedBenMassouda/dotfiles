import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs

// Panel that drops down under the right end of the bar on the focused monitor.
// Open/close with Globals.togglePanel(name); closes on Escape or a click outside.
PanelWindow {
    id: panel

    required property string name
    default property alias content: column.data

    visible: Globals.panel === name
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors.top: true
    anchors.right: true
    margins.top: Theme.gap
    margins.right: 8
    exclusiveZone: 0
    implicitWidth: 400
    implicitHeight: Math.min(column.implicitHeight + 28, (screen?.height ?? 1080) - Theme.barHeight - 40)
    color: "transparent"

    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        active: panel.visible
        windows: [panel]
        onCleared: Globals.closePanel()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.popup
        border.color: Theme.accent
        border.width: Theme.border

        Flickable {
            anchors.fill: parent
            anchors.margins: 14
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: column
                width: parent.width
                spacing: 14
                focus: true
                Keys.onEscapePressed: Globals.closePanel()
            }
        }
    }
}
