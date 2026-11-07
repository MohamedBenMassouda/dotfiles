import QtQuick
import QtQuick.Controls as Controls   // prefixed: its Label would replace the bar's Label
import QtQuick.Layouts
import Quickshell
import qs

// Date and time, e.g. "Fri 06 Nov  23:42". Hover to show a calendar
// (scroll on it to change month, click the arrows, or the title to go back to today).
Item {
    id: root

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Label {
        id: label
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        font.bold: true
    }

    HoverHandler {
        id: clockHover
    }

    // Open while the pointer is on the clock or the calendar; a short delay
    // lets the pointer travel from one to the other without closing it.
    readonly property bool hovered: clockHover.hovered || calendarHover.hovered
    onHoveredChanged: {
        if (hovered) {
            closeDelay.stop();
            calendar.month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1);
            popup.visible = true;
        } else {
            closeDelay.restart();
        }
    }

    Timer {
        id: closeDelay
        interval: 300
        onTriggered: popup.visible = false
    }

    PopupWindow {
        id: popup

        visible: false
        color: "transparent"
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight

        // centred under the clock island
        anchor.item: root
        anchor.rect.x: 0
        anchor.rect.y: 0
        anchor.rect.width: root.width
        anchor.rect.height: root.height + 16
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: card

            implicitWidth: content.implicitWidth + 28
            implicitHeight: content.implicitHeight + 24
            radius: Theme.radius
            color: Theme.popup
            border.color: Theme.accent
            border.width: Theme.border

            HoverHandler {
                id: calendarHover
            }

            WheelHandler {
                onWheel: event => calendar.shift(event.angleDelta.y > 0 ? -1 : 1)
            }

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                spacing: 8

                QtObject {
                    id: calendar
                    property date month: new Date()
                    function shift(n) {
                        month = new Date(month.getFullYear(), month.getMonth() + n, 1);
                    }
                }

                // weather (Globals, wttr.in): ☁️ 19°C Cloudy · Town, sunrise / sunset
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4
                    visible: Globals.weather !== null
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Globals.weather ? Globals.weather.icon + "  " + Globals.weather.temp + "  " + Globals.weather.condition : ""
                        color: Theme.foreground
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 2
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Globals.weather ? Globals.weather.place + "   " + String.fromCodePoint(0xF059C) + " " + Globals.weather.sunrise
                                                + "   " + String.fromCodePoint(0xF059B) + " " + Globals.weather.sunset : ""
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                // ‹  November 2026  ›
                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "󰅁"
                        color: prevArea.containsMouse ? Theme.foreground : Theme.dim
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.shift(-1)
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDate(calendar.month, "MMMM yyyy")
                        font.bold: true
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
                        }
                    }

                    Label {
                        text: "󰅂"
                        color: nextArea.containsMouse ? Theme.foreground : Theme.dim
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.shift(1)
                        }
                    }
                }

                Controls.DayOfWeekRow {
                    Layout.fillWidth: true
                    locale: grid.locale
                    delegate: Label {
                        required property string shortName
                        text: shortName.slice(0, 2)
                        color: Theme.dim
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSize - 1
                    }
                }

                Controls.MonthGrid {
                    id: grid
                    Layout.fillWidth: true
                    locale: Qt.locale("en_GB")    // weeks start on Monday
                    month: calendar.month.getMonth()
                    year: calendar.month.getFullYear()

                    delegate: Rectangle {
                        required property var model
                        implicitWidth: 34
                        implicitHeight: 28
                        radius: 6
                        color: model.today ? Theme.accent : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.month === grid.month ? Theme.foreground : Qt.alpha(Theme.foreground, 0.3)
                            font.bold: model.today
                        }
                    }
                }
            }
        }
    }
}
