//@ pragma IconTheme breeze-dark
// Lock screen, run as its own process so the bar can't take it down:
//   qs -p ~/.config/quickshell/lock.qml          (hypr/scripts/QsLock.sh does this)
//   QS_LOCK_PREVIEW=1 qs -p ...lock.qml          normal window, Escape closes it, for testing
// Password is checked by PAM with hyprlock's config (/etc/pam.d/hyprlock).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs

ShellRoot {
    id: root

    readonly property bool preview: Quickshell.env("QS_LOCK_PREVIEW") === "1"
    readonly property string marker: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-lock-active"

    property bool busy: false
    property bool failed: false
    property string message: ""
    property string password: ""

    function tryUnlock(text) {
        if (busy || text === "") return;
        password = text;
        failed = false;
        message = "";
        busy = true;
        pam.start();
    }

    function unlock() {
        lock.locked = false;
        Quickshell.execDetached(["rm", "-f", marker]);
        Qt.quit();
    }

    // editing these files while locked must not reload the lock
    Component.onCompleted: Quickshell.watchFiles = false

    PamContext {
        id: pam
        config: "hyprlock"

        onPamMessage: {
            if (responseRequired) respond(root.password);
            else if (messageIsError) root.message = message;
        }

        onCompleted: result => {
            root.busy = false;
            root.password = "";
            if (result === PamResult.Success) root.unlock();
            else root.failed = true;
        }

        onError: error => {
            root.busy = false;
            root.password = "";
            root.failed = true;
            root.message = PamError.toString(error);
        }
    }

    // test hook: qs -p lock.qml ipc call lock tryPassword <text>
    IpcHandler {
        target: "lock"
        function tryPassword(text: string): void { root.tryUnlock(text); }
        function state(): string { return root.busy ? "busy" : root.failed ? "failed" : "idle"; }
    }

    WlSessionLock {
        id: lock

        locked: !root.preview

        // the compositor confirmed the lock: tell QsLock.sh it worked
        onSecureChanged: if (secure) Quickshell.execDetached(["touch", root.marker])

        WlSessionLockSurface {
            color: Theme.background
            LockContent { lock: root }
        }
    }

    // preview: one fullscreen window on the focused monitor instead of a real lock
    Loader {
        active: root.preview

        sourceComponent: PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.background
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            LockContent {
                lock: root
                focus: true
                Keys.onEscapePressed: Qt.quit()
            }
        }
    }
}
