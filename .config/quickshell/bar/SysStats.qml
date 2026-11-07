import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// CPU usage and used memory, refreshed every 2 seconds from /proc.
RowLayout {
    id: root

    property int cpu: 0
    property real memGb: 0
    property var lastCpu: null

    spacing: 12

    FileView {
        id: stat
        path: "/proc/stat"
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();

            // cpu  user nice system idle iowait irq softirq steal
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                if (dt > 0)
                    root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / dt));
            }
            root.lastCpu = { idle, total };

            const mem = {};
            for (const line of meminfo.text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) mem[m[1]] = Number(m[2]);
            }
            root.memGb = (mem.MemTotal - mem.MemAvailable) / 1048576;
        }
    }

    Label {
        text: String.fromCodePoint(0xF0EE0) + " " + root.cpu + "%"
        color: root.cpu > 85 ? Theme.urgent : Theme.cpu
    }

    Label {
        text: String.fromCodePoint(0xF035B) + " " + root.memGb.toFixed(1) + "G"
        color: Theme.memory
    }
}
