//@ pragma IconTheme breeze-dark
// Login screen (greetd greeter), same look as the lock screen.
// Runs inside its own small Hyprland (greeter/hyprland.lua) as the "greeter" user.
//   Enter: log in   ·  click the name: next user  ·  click the session: next session
// Test it from your desktop without logging in:
//   GREETER_PREVIEW=1 qs -p ~/dotfiles/greeter/quickshell/shell.qml   (Escape closes)
// For the preview it needs Theme.qml / colors.json next to it; install.sh copies them.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs

ShellRoot {
    id: root

    readonly property bool preview: Quickshell.env("GREETER_PREVIEW") === "1"

    // users from /etc/passwd: real accounts with a login shell
    property var users: []
    property int userIndex: 0
    readonly property string user: users.length ? users[userIndex].name : ""

    // sessions from /usr/share/wayland-sessions; Hyprland (uwsm-managed) first
    property var sessions: []
    property int sessionIndex: 0
    readonly property var session: sessions.length ? sessions[sessionIndex] : null

    property string password: ""
    property bool busy: false
    property string message: ""
    property bool failed: false

    function login(pw) {
        if (busy || user === "" || !session) return;
        failed = false;
        message = "";
        if (preview) {
            message = "Preview: would log in " + user + " to " + session.name;
            return;
        }
        password = pw;
        busy = true;
        Greetd.createSession(user);
    }

    function fail(text) {
        busy = false;
        password = "";
        failed = true;
        message = text;
        if (Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: {
            root.users = text().split("\n").map(l => l.split(":"))
                .filter(f => f.length > 6 && +f[2] >= 1000 && +f[2] < 60000 && !/nologin|false$/.test(f[6]))
                .map(f => ({ name: f[0], full: (f[4] || "").split(",")[0] || f[0] }));
        }
    }

    Process {
        running: true
        // "Name|Exec" per session file, field codes like %U removed
        command: ["sh", "-c", "for f in /usr/share/wayland-sessions/*.desktop; do "
            + "n=$(sed -n 's/^Name=//p' \"$f\" | head -1); e=$(sed -n 's/^Exec=//p' \"$f\" | head -1); "
            + "[ -n \"$e\" ] && printf '%s|%s\\n' \"$n\" \"$e\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = text.trim().split("\n").filter(l => l.includes("|")).map(l => {
                    const i = l.indexOf("|");
                    return { name: l.slice(0, i), exec: l.slice(i + 1).replace(/\s%\w/g, "").trim() };
                });
                list.sort((a, b) => (b.name === "Hyprland (uwsm-managed)") - (a.name === "Hyprland (uwsm-managed)"));
                root.sessions = list;
            }
        }
    }

    Connections {
        target: Greetd
        enabled: !root.preview

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password);
            else if (error) root.message = message;
        }

        function onAuthFailure(message) {
            root.fail("Wrong password");
        }

        function onError(error) {
            root.fail(error);
        }

        function onReadyToLaunch() {
            root.password = "";
            root.message = "Starting " + root.session.name + "…";
            Greetd.launch(root.session.exec.split(/\s+/), ["XDG_SESSION_TYPE=wayland"], true);
        }
    }

    // one window per monitor; the login form goes on the monitor at the top-left
    // of your layout (your main one), the others show the clock only
    Variants {
        model: Quickshell.screens

        GreeterScreen {
            greeter: root
        }
    }
}
