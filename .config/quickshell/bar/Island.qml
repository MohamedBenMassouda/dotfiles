import QtQuick
import QtQuick.Layouts
import qs

// A rounded, bordered pill that lays its children out in a row, with a bit of
// spider web in the top-left and bottom-right corners.
Rectangle {
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.panel
    border.color: Theme.accent
    border.width: Theme.border

    // web in two corners, like the suit's texture
    WebCorner {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.border
        implicitWidth: 16
        implicitHeight: 16
        corner: 0
    }
    WebCorner {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Theme.border
        implicitWidth: 16
        implicitHeight: 16
        corner: 3
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
