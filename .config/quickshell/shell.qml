//@ pragma UseQApplication
// (needed for tray menus)
//@ pragma IconTheme breeze-dark
import Quickshell
import Quickshell.Io
import qs
import qs.bar
import qs.panels

// Entry point: one bar per monitor, the top-centre flyout (with notifications),
// and the side panels.
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

    // qs ipc call panel toggle control|notifications   (SUPER+N / SUPER+H)
    // qs ipc call panel dnd
    IpcHandler {
        target: "panel"

        function toggle(name: string): void {
            Globals.togglePanel(name);
        }

        // game mode: pause / resume the theme pack (scripts/Pack.sh pause|resume)
        function packPaused(on: bool): void {
            Pack.paused = on;
        }

        // next suit of the theme pack (Spider-Man: Advanced, Classic, Gwen, ...)
        function suit(): void {
            Pack.nextSuit();
        }

        // next desktop theme pack (none -> spiderman -> ... -> none)
        function pack(): void {
            Pack.next();
        }

        function dnd(): void {
            Globals.dnd = !Globals.dnd;
        }

        function clearNotifications(): void {
            Notifs.clearAll();
        }

        function clearApp(app: string): void {
            Notifs.clearApp(app);
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            visible: shell.barVisible
        }
    }

    // the pack mascot crawls along the top of empty workspaces
    Variants {
        model: Quickshell.screens

        DesktopMascot {}
    }

    // volume / media / brightness / toast flyout + notification popups
    Osd {}

    // SUPER+A: qs ipc call overview toggle
    Overview {}

    ControlCenter {}
    NotificationCenter {}
}
