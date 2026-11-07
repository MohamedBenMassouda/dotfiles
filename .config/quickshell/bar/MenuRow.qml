import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs

// One row of a TrayMenu: optional check mark/icon, label, optional › for submenus.
Rectangle {
    id: row

    property string label: ""
    property string glyph: ""          // check / radio mark or a symbol
    property string iconSource: ""     // app-provided icon
    property string trailing: ""       // › for submenus
    property bool dimmed: false

    signal activated

    Layout.fillWidth: true
    implicitWidth: content.implicitWidth + 20
    implicitHeight: 30
    radius: 6
    color: mouse.containsMouse && enabled ? Theme.surface : "transparent"
    opacity: enabled ? 1 : 0.4

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // fixed-width slot so labels line up whether or not there is a mark
        Item {
            implicitWidth: 16
            implicitHeight: 16

            IconImage {
                anchors.fill: parent
                visible: row.glyph === "" && row.iconSource !== ""
                source: row.iconSource
            }

            Label {
                anchors.centerIn: parent
                visible: row.glyph !== ""
                text: row.glyph
                color: Theme.accent
            }
        }

        Label {
            Layout.fillWidth: true
            text: row.label
            color: row.dimmed ? Theme.dim : Theme.foreground
            elide: Text.ElideRight
        }

        Label {
            visible: row.trailing !== ""
            text: row.trailing
            color: Theme.dim
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (row.enabled) row.activated()
    }
}
