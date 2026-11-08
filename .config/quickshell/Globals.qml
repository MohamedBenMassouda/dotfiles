pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Shell-wide state shared by the bar, panels and flyouts.
Singleton {
    id: root

    property bool keepAwake: false       // idle inhibitor (bar coffee icon)
    // each monitor's bar islands as [left, right] x ranges, left to right (bar/Bar.qml);
    // the desktop crawler clings under them and swings across the gaps
    property var islands: ({})
    property bool dnd: false             // do not disturb: no notification popups
    property string panel: ""            // open side panel: "", "control" or "notifications"

    property int updates: 0              // pending pacman + AUR updates (bar/Updates.qml)
    property int news: 0                 // unread Arch news, shown before updating (hypr/scripts/ArchUpdate.py)

    // checked once for all bars (two checkupdates at once fight over the db lock)
    function upgrade() {
        upgradeTerm.running = true;
    }

    Process {
        id: checkUpdates
        command: ["sh", "-c", "{ checkupdates; yay -Qua; } 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.updates = parseInt(text.trim()) || 0
        }
    }

    Process {
        id: upgradeTerm
        // unread Arch news first (with a chance to cancel), then yay -Syu
        command: ["kitty", "--class", "updates", "-e", "sh", "-c", root.scripts + "/ArchUpdate.py; echo; read -rp 'Done, press Enter to close' _"]
        onExited: {
            checkUpdates.running = true;
            checkNews.running = true;
        }
    }

    Process {
        id: checkNews
        command: [root.scripts + "/ArchUpdate.py", "--unread"]
        stdout: StdioCollector {
            onStreamFinished: root.news = parseInt(text.trim()) || 0
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkUpdates.running = true;
            checkNews.running = true;
        }
    }

    // ask the top-centre flyout (Osd.qml) to show: "volume" or "mic"
    signal flyout(string kind)

    // ask the flyout for a toast card (same kinds as `qs ipc call osd toast`)
    signal toast(string kind, string title, string subtitle)

    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"

    // ---- keep awake while media plays (music or video) ----
    readonly property bool mediaPlaying: Mpris.players.values.some(p => p.isPlaying)

    // ---- weather (wttr.in, by IP location), every 30 min ----
    // { icon, temp, condition, place, sunrise: "06:45", sunset: "17:13" }
    property var weather: null

    Process {
        id: fetchWeather
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=%c|%t|%C|%l|%S|%s"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("|");
                if (f.length < 6) return;
                root.weather = { icon: f[0].trim(), temp: f[1].replace("+", ""), condition: f[2].trim(),
                                 place: f[3].split(",")[0], sunrise: f[4].slice(0, 5), sunset: f[5].slice(0, 5) };
                root.checkSun();
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchWeather.running = true
    }

    // ---- calendar (hypr/scripts/Calendar.py: Google via private iCal address) ----
    // events: [{ title, start, end, allDay, calendar, location }], next 7 days
    property var events: []
    property string calendarError: ""
    property var reminded: ({})          // "title|start" already announced

    Process {
        id: fetchCalendar
        command: [root.scripts + "/Calendar.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.calendarError = data.error ?? "";
                    root.events = Array.isArray(data) ? data : [];
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000          // the script caches downloads for 15 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchCalendar.running = true
    }

    // flyout 10 minutes before each timed event
    Timer {
        interval: 30 * 1000
        running: root.events.length > 0
        repeat: true
        onTriggered: {
            const now = Date.now();
            for (const e of root.events) {
                if (e.allDay) continue;
                const mins = (new Date(e.start).getTime() - now) / 60000;
                const key = e.title + "|" + e.start;
                if (mins > 0 && mins <= 10 && !root.reminded[key]) {
                    root.reminded[key] = true;
                    root.toast("calendar", e.title, "In " + Math.ceil(mins) + " min · " + e.start.slice(11)
                               + (e.location ? " · " + e.location : ""));
                }
            }
        }
    }

    // ---- night light follows the sun: on at sunset, off at sunrise ----
    // (a manual toggle in between stays until the next sunrise / sunset)
    property string sunPhase: ""

    function checkSun() {
        if (!weather) return;
        const now = Qt.formatTime(new Date(), "HH:mm");
        const phase = now >= weather.sunrise && now < weather.sunset ? "day" : "night";
        if (phase === sunPhase) return;
        sunPhase = phase;
        Quickshell.execDetached([scripts + "/Hyprsunset.sh", phase === "night" ? "on" : "off"]);
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.checkSun()
    }

    // ---- focus timer: 25 min work (do-not-disturb on), then 5 min break ----
    property string focusPhase: ""       // "", "work" or "break"
    property double focusEnd: 0
    property int focusLeft: 0            // seconds
    property bool dndBeforeFocus: false

    function toggleFocus() {
        if (focusPhase === "") {
            dndBeforeFocus = dnd;
            dnd = true;
            startFocus("work", 25);
            toast("focus", "Focus", "25 minutes, notifications muted");
        } else {
            focusPhase = "";
            dnd = dndBeforeFocus;
            toast("focus", "Focus stopped", "");
        }
    }

    function startFocus(phase, minutes) {
        focusPhase = phase;
        focusEnd = Date.now() + minutes * 60 * 1000;
        focusLeft = minutes * 60;
    }

    Timer {
        interval: 1000
        running: root.focusPhase !== ""
        repeat: true
        onTriggered: {
            root.focusLeft = Math.max(0, Math.round((root.focusEnd - Date.now()) / 1000));
            if (root.focusLeft > 0) return;
            if (root.focusPhase === "work") {
                root.dnd = root.dndBeforeFocus;
                root.startFocus("break", 5);
                root.toast("focus", "Time for a break", "5 minutes");
            } else {
                root.focusPhase = "";
                root.toast("focus", "Break over", "Start another round from quick settings");
            }
        }
    }

    // ---- phone (KDE Connect): name + battery of the first reachable device ----
    // { id, name, battery, charging } or null
    property var phone: null

    function phoneDo(args) {
        if (phone) Quickshell.execDetached(["kdeconnect-cli", "-d", phone.id].concat(args));
    }

    Process {
        id: checkPhone
        command: ["sh", "-c", "id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -1); [ -n \"$id\" ] || exit 0; "
            + "p=/modules/kdeconnect/devices/$id; b=org.kde.kdeconnect.device.battery; "
            + "echo \"$id|$(kdeconnect-cli -a --name-only | head -1)|"
            + "$(busctl --user get-property org.kde.kdeconnect $p/battery $b charge | cut -d' ' -f2)|"
            + "$(busctl --user get-property org.kde.kdeconnect $p/battery $b isCharging | cut -d' ' -f2)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("|");
                root.phone = f.length === 4 ? { id: f[0], name: f[1], battery: parseInt(f[2]), charging: f[3] === "true" } : null;
            }
        }
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkPhone.running = true
    }

    property string lastClosed: ""
    property double lastClosedAt: 0

    function togglePanel(name) {
        // clicking the bar icon of an open panel first closes it through the
        // focus grab (click outside); don't reopen it right away
        if (panel === "" && lastClosed === name && Date.now() - lastClosedAt < 300) return;
        panel = panel === name ? "" : name;
    }

    function closePanel() {
        if (panel === "") return;
        lastClosed = panel;
        lastClosedAt = Date.now();
        panel = "";
    }
}
