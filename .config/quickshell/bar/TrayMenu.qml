import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs

// A tray app's menu (Wi-Fi, Discord...) drawn in the bar's own style instead
// of Qt's default widgets. Submenus open in place with a "back" row.
// Closes when an item is picked or when you click elsewhere.
PopupWindow {
    id: root

    required property var handle      // the tray item's menu
    required property Item anchorItem

    // submenu path: [root menu, submenu, sub-submenu...]
    property var stack: []

    function open() {
        stack = [handle];
        visible = true;
    }

    function close() {
        visible = false;
    }

    visible: false
    grabFocus: true                    // clicking outside closes it
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // centred under the icon, just below the bar island
    anchor.item: anchorItem
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: anchorItem.width
    anchor.rect.height: anchorItem.height + 14
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    // One opener per level: a submenu entry lives only while its parent menu
    // is open, so the parent's opener has to stay alive (max 3 levels deep).
    QsMenuOpener { id: level0; menu: root.stack[0] ?? null }
    QsMenuOpener { id: level1; menu: root.stack[1] ?? null }
    QsMenuOpener { id: level2; menu: root.stack[2] ?? null }
    readonly property QsMenuOpener opener: [level0, level1, level2][Math.max(0, stack.length - 1)]

    Rectangle {
        id: card

        implicitWidth: Math.max(220, list.implicitWidth + 12)
        implicitHeight: list.implicitHeight + 12
        radius: Theme.radius
        color: Theme.popup
        border.color: Theme.accent
        border.width: Theme.border

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            // back row inside a submenu
            MenuRow {
                visible: root.stack.length > 1
                glyph: String.fromCodePoint(0xF0141)
                label: "Back"
                dimmed: true
                onActivated: root.stack = root.stack.slice(0, -1)
            }

            Repeater {
                model: root.opener.children

                delegate: Loader {
                    id: row

                    required property var modelData

                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separator : entry

                    Component {
                        id: separator
                        Rectangle {
                            implicitHeight: 9
                            color: "transparent"
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                height: 1
                                color: Qt.alpha(Theme.foreground, 0.12)
                            }
                        }
                    }

                    Component {
                        id: entry
                        MenuRow {
                            readonly property var item: row.modelData
                            readonly property bool checkable: item.buttonType !== QsMenuButtonType.None
                            readonly property bool checked: item.checkState === Qt.Checked

                            label: item.text.replace(/_/g, "")      // drop mnemonic underscores
                            iconSource: item.icon
                            // ✓ for checkboxes, ● for radio buttons, › for submenus
                            glyph: checkable && checked ? String.fromCodePoint(item.buttonType === QsMenuButtonType.RadioButton ? 0xF0765 : 0xF012C) : ""
                            trailing: item.hasChildren ? String.fromCodePoint(0xF0142) : ""
                            enabled: item.enabled
                            onActivated: {
                                if (item.hasChildren && root.stack.length < 3) {
                                    root.stack = root.stack.concat([item]);
                                } else {
                                    item.triggered();
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
