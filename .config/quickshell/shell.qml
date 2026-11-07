//@ pragma UseQApplication
// (needed for tray menus)
//@ pragma IconTheme breeze-dark
import Quickshell
import Quickshell.Io
import qs.bar

// Entry point: one bar per monitor, plus the media/volume flyout.
ShellRoot {
    id: shell

    property bool barVisible: true

    // SUPER+B: qs ipc call bar toggle
    IpcHandler {
        target: "bar"

        function toggle(): void {
            shell.barVisible = !shell.barVisible;
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            visible: shell.barVisible
        }
    }

    // media / volume flyout (qs ipc call osd volume|media)
    Osd {}
}
