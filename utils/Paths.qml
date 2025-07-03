pragma Singleton

import Quickshell
import Qt.labs.platform

Singleton {
    id: root

    readonly property url home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property url pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]

    readonly property url data: `${StandardPaths.standardLocations(StandardPaths.GenericDataLocation)[0]}/caelestia`
    readonly property url state: `${StandardPaths.standardLocations(StandardPaths.GenericStateLocation)[0]}/caelestia`
    readonly property url cache: `${StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]}/caelestia`
    readonly property url config: `${StandardPaths.standardLocations(StandardPaths.GenericConfigLocation)[0]}/caelestia`

    readonly property url imagecache: `${cache}/imagecache`

    function expandTilde(path: string): string {
        return strip(path.replace("~", root.home.toString()));
    }

    function shortenHome(path: string): string {
        return path.replace(strip(root.home.toString()), "~");
    }

    function strip(path: url): string {
        return path.toString().replace("file://", "");
    }

    function mkdir(path: url): void {
        // Use shell-agnostic approach for NixOS compatibility
        const mkdirCmd = Quickshell.env("SHELL")?.includes("fish") ? "mkdir" : "mkdir";
        Quickshell.execDetached([mkdirCmd, "-p", strip(path)]);
    }

    function copy(from: url, to: url): void {
        // Use shell-agnostic approach for NixOS compatibility
        const cpCmd = Quickshell.env("SHELL")?.includes("fish") ? "cp" : "cp";
        Quickshell.execDetached([cpCmd, strip(from), strip(to)]);
    }
}
