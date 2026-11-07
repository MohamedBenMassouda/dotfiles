pragma Singleton

import Quickshell

// Finds an icon for an app from whatever name we have (app id, window class,
// player name). Tries the app's desktop file, then a desktop file whose window
// class matches (e.g. Spotify's flatpak), then the name itself as an icon.
// Returns "" when nothing matches, so callers can show their own fallback.
Singleton {
    function forApp(name) {
        if (!name)
            return "";
        const lower = name.toLowerCase();
        const entry = DesktopEntries.heuristicLookup(name)
            ?? DesktopEntries.applications.values.find(e => e.startupClass.toLowerCase() === lower)
            ?? DesktopEntries.applications.values.find(e => e.id.toLowerCase().includes(lower))
            ?? null;
        return Quickshell.iconPath(entry?.icon ?? "", true)
            || Quickshell.iconPath(lower, true)
            || Quickshell.iconPath(lower.split("-")[0], true);
    }
}
