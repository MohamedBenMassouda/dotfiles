import QtQuick
import QtQuick.Layouts
import qs

// A rounded, bordered pill that lays its children out in a row, with the
// pack's corner ornament top-left and bottom-right.
Rectangle {
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.panel
    border.color: Theme.accent
    border.width: Theme.border

    // pack ornament in two corners (web for Spider-Man)
    Loader {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.border
        width: 16
        height: 16
        source: Pack.flag("corners") ? Pack.url("Corner.qml") : ""
        onLoaded: item.corner = 0
    }
    Loader {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Theme.border
        width: 16
        height: 16
        source: Pack.flag("corners") ? Pack.url("Corner.qml") : ""
        onLoaded: item.corner = 3
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
