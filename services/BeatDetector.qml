pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real bpm: 1

    Process {
        running: true
        command: [
            Quickshell.env("CAELESTIA_BD_PATH") || 
            `${Quickshell.env("HOME")}/.local/lib/caelestia/beat_detector` ||
            "/usr/lib/caelestia/beat_detector",
            "--no-log", "--no-stats", "--no-visual"
        ]
        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/BPM: ([0-9]+\.[0-9])/);
                if (match)
                    root.bpm = parseFloat(match[1]);
            }
        }
    }
}
