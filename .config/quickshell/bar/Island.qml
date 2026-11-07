import QtQuick
import QtQuick.Layouts
import qs

// A rounded, bordered pill that lays its children out in a row.
Rectangle {
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.panel
    border.color: Theme.accent
    border.width: Theme.border

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
