import QtQuick
import QtQuick.Controls as Controls   // prefixed: its Label would replace the bar's Label
import QtQuick.Layouts
import Quickshell
import qs

// Date and time, e.g. "Fri 06 Nov  23:42". Hover to show weather, a calendar
// (scroll on it to change month, click the arrows, or the title to go back to today)
// and the next events from Google Calendar (Globals.events).
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
                    // days with events get a dot
                    readonly property var busy: Globals.events.map(e => e.start.slice(0, 10))
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

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 4
                            height: 4
                            radius: 2
                            color: model.today ? Theme.foreground : Theme.accent
                            visible: grid.busy.includes(Qt.formatDate(model.date, "yyyy-MM-dd"))
                        }
                    }
                }

                // ---- upcoming events ----
                ColumnLayout {
                    id: agenda
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    visible: upcoming.length > 0 || Globals.calendarError !== ""
                    spacing: 4

                    // not finished yet, at most 6
                    readonly property var upcoming: {
                        const now = Qt.formatDateTime(clock.date, "yyyy-MM-ddTHH:mm");
                        return Globals.events.filter(e => e.allDay ? e.end > now.slice(0, 10) : e.end > now).slice(0, 6);
                    }

                    function dayName(d) {
                        const today = Qt.formatDate(clock.date, "yyyy-MM-dd");
                        const tomorrow = Qt.formatDate(new Date(clock.date.getTime() + 86400000), "yyyy-MM-dd");
                        return d === today ? "Today" : d === tomorrow ? "Tomorrow" : Qt.formatDate(new Date(d + "T00:00"), "dddd");
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Qt.alpha(Theme.foreground, 0.12)
                    }

                    Label {
                        visible: Globals.calendarError !== ""
                        text: Globals.calendarError
                        color: Theme.dim
                        font.pixelSize: Theme.fontSize - 2
                    }

                    Repeater {
                        model: agenda.upcoming

                        delegate: ColumnLayout {
                            required property var modelData
                            required property int index
                            readonly property string day: modelData.start.slice(0, 10)
                            Layout.fillWidth: true
                            spacing: 2

                            // day heading when the day changes
                            Label {
                                Layout.topMargin: 4
                                visible: parent.index === 0 || agenda.upcoming[parent.index - 1].start.slice(0, 10) !== parent.day
                                text: agenda.dayName(parent.day)
                                color: Theme.accent
                                font.bold: true
                                font.pixelSize: Theme.fontSize - 1
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Label {
                                    Layout.preferredWidth: 46
                                    text: parent.parent.modelData.allDay ? "all day" : parent.parent.modelData.start.slice(11)
                                    color: Theme.dim
                                    font.pixelSize: Theme.fontSize - 1
                                }

                                Label {
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 200
                                    text: parent.parent.modelData.title
                                    elide: Text.ElideRight
                                    font.pixelSize: Theme.fontSize - 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
