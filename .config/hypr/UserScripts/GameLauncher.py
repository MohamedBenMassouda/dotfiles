#!/usr/bin/env python3
"""Rofi game launcher (SUPER+CTRL+G).

Lists, sorted by name:
  - installed Steam games (every Steam library)    -> launched through Steam
  - non-Steam games added to Steam                 -> launched through Steam (keeps their Proton prefix)
  - Windows games in /mnt/Data/Games                -> launched with Proton via umu-run,
                                                      one prefix per game in /mnt/Data/Games/.umu/

Recently played games come first, then A-Z; each row shows playtime and when
it was last played (~/.local/state/game-launcher.json). Enter plays (Windows
games inside gamescope), Alt+Enter plays a Windows game without gamescope, Shift+Enter adds the MangoHud FPS overlay.
Windows games show the icon from their .exe (icoutils; cached in
~/.cache/game-launcher/icons). Windows games run through GameRun.sh
(game mode for the session, gamemoderun, playtime).

Switch games (folders running yuzu.exe) start in the native Eden emulator
(Flatpak dev.eden_emu.eden) when it's installed: the game's .nsp/.xci, or the
game installed in yuzu's storage; Alt+Enter still starts the Windows yuzu.

`GameLauncher.py --list` prints what was found instead of opening rofi.
"""
import html
import json
import time
import os
import re
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
STEAM = f"{HOME}/.local/share/Steam"
GAMES_DIR = "/mnt/Data/Games"
PREFIXES = f"{GAMES_DIR}/.umu"
SKIP_DIRS = {"GameSaves"}
STATE = f"{HOME}/.local/state/game-launcher.json"
ICONS = f"{HOME}/.cache/game-launcher/icons"
RUN = os.path.join(os.path.dirname(os.path.realpath(__file__)), "GameRun.sh")
DOWNLOAD = os.path.join(os.path.dirname(os.path.realpath(__file__)), "UmuDownload.sh")
# helper executables and tools that are not the game itself
NOT_GAME = re.compile(
    r"unins|setup|install|redist|crash|createdump|dedicatedserver|server\.exe|qtwebengine|"
    r"yuzu-(cmd|room)|_ea\.exe$|ubisoft|prereq|easyanticheat|dotnet|dxsetup|ddu|rufus|"
    r"helper|cefprocess|ccsetup|uploader|reporter|oalinst|quicksfv",
    re.I,
)
# folders inside a game that only hold redistributables, plugins or engine tools
SKIP_SUBDIRS = re.compile(r"^(_?(Common)?Redist|Plugins|Engine|DirectX|Support)$", re.I)
NOT_STEAM_GAME = re.compile(r"^(Proton|Steam Linux Runtime|Steamworks Common)", re.I)


def notify(msg):
    subprocess.run(["notify-send", "-e", "-u", "low", " Games", msg])


def steam_libraries():
    try:
        text = open(f"{STEAM}/steamapps/libraryfolders.vdf").read()
    except OSError:
        return []
    return re.findall(r'"path"\s+"([^"]+)"', text)


def steam_games():
    for lib in steam_libraries():
        apps = f"{lib}/steamapps"
        if not os.path.isdir(apps):
            continue
        for f in os.listdir(apps):
            if not (f.startswith("appmanifest_") and f.endswith(".acf")):
                continue
            text = open(f"{apps}/{f}", errors="replace").read()
            appid = re.search(r'"appid"\s+"(\d+)"', text)
            name = re.search(r'"name"\s+"([^"]+)"', text)
            if appid and name and not NOT_STEAM_GAME.match(name.group(1)):
                yield name.group(1), steam_icon(appid.group(1)), ["steam", f"steam://rungameid/{appid.group(1)}"], None


def steam_icon(appid):
    """Steam's small game icon (librarycache/<appid>/<hash>.jpg), else the Steam icon."""
    d = f"{STEAM}/appcache/librarycache/{appid}"
    try:
        jpgs = [f for f in os.listdir(d) if f.endswith(".jpg")]
    except OSError:
        jpgs = []
    return f"{d}/{jpgs[0]}" if jpgs else "steam"


def steam_shortcuts():
    """Non-Steam games from Steam's binary shortcuts.vdf: (name, exe, launch command)."""
    userdata = f"{STEAM}/userdata"
    if not os.path.isdir(userdata):
        return
    for user in os.listdir(userdata):
        try:
            data = open(f"{userdata}/{user}/config/shortcuts.vdf", "rb").read()
        except OSError:
            continue
        pattern = rb"\x02appid\x00(.{4})\x01AppName\x00([^\x00]*)\x00\x01Exe\x00([^\x00]*)\x00"
        for m in re.finditer(pattern, data, re.S | re.I):
            appid = int.from_bytes(m.group(1), "little")
            exe = m.group(3).decode(errors="replace").strip('"')
            if not os.path.isfile(exe):
                continue  # game was deleted but the shortcut stayed
            gameid = (appid << 32) | 0x02000000
            name = clean(os.path.basename(os.path.dirname(exe)))
            yield name, "steam", ["steam", f"steam://rungameid/{gameid}"], exe


def clean(name):
    name = re.sub(r"[-.]?steamrip\.com$", "", name, flags=re.I)
    name = re.sub(r"[ .]v\d[\w.]*(-P2P)?$", "", name)
    name = re.sub(r"-(Windows|P2P)$", "", name)
    if " " not in name:
        name = name.replace("-", " ")
    return name.strip()


def main_exe(folder, max_depth=4):
    """The game binary: the shallowest non-helper .exe, largest one on ties.
    Shallowest wins because the top-level .exe is the one meant to be started
    (Unreal's root .exe starts the Shipping binary; Unity's sits next to its _Data)."""
    best, best_key = None, None
    base = folder.rstrip("/").count("/")
    for root, dirs, files in os.walk(folder):
        depth = root.count("/") - base
        dirs[:] = [] if depth >= max_depth else [d for d in dirs if not SKIP_SUBDIRS.match(d)]
        for f in files:
            if f.lower().endswith(".exe") and not NOT_GAME.search(f):
                path = os.path.join(root, f)
                key = (depth, -os.path.getsize(path))
                if best_key is None or key < best_key:
                    best, best_key = path, key
    return best


def folder_games(skip_exes, skip_names):
    if not os.path.isdir(GAMES_DIR):
        return
    for entry in os.scandir(GAMES_DIR):
        if not entry.is_dir() or entry.name.startswith(".") or entry.name in SKIP_DIRS or NOT_GAME.search(entry.name):
            continue
        exe = main_exe(entry.path)
        if not exe or exe in skip_exes or norm(clean(entry.name)) in skip_names:
            continue  # already listed through Steam
        slug = re.sub(r"[^a-z0-9]+", "-", clean(entry.name).lower()).strip("-")
        yield clean(entry.name), exe_icon(exe, slug), ["umu-run", exe], (exe, slug)


EDEN = ["flatpak", "run", "dev.eden_emu.eden"]
SWITCH_EXE = re.compile(r"^(yuzu|suyu|eden|citron)\.exe$", re.I)


def eden_installed():
    return subprocess.run(["flatpak", "info", "dev.eden_emu.eden"], capture_output=True).returncode == 0


def switch_rom(exe):
    """For a folder that runs a Windows Switch emulator: the game to give Eden,
    a .nsp/.xci next to it, else the largest program installed in its storage."""
    if not SWITCH_EXE.match(os.path.basename(exe)):
        return None
    folder = os.path.dirname(exe)
    roms = []
    for root, _dirs, files in os.walk(folder):
        roms += [os.path.join(root, f) for f in files if f.lower().endswith((".nsp", ".xci", ".nsz", ".xcz"))]
    if not roms:
        reg = f"{folder}/user/nand/user/Contents/registered"
        if os.path.isdir(reg):
            roms = [os.path.join(reg, f) for f in os.listdir(reg) if f.endswith(".nca")]
    return max(roms, key=os.path.getsize) if roms else None


def other_exes(exe, limit=4):
    """Other game .exe files in the same game folder, largest first."""
    top = exe[len(GAMES_DIR) + 1:].split("/")[0]
    found = []
    for root, dirs, files in os.walk(f"{GAMES_DIR}/{top}"):
        dirs[:] = [d for d in dirs if not SKIP_SUBDIRS.match(d)]
        found += [os.path.join(root, f) for f in files
                  if f.lower().endswith(".exe") and not NOT_GAME.search(f) and os.path.join(root, f) != exe]
    return sorted(found, key=os.path.getsize, reverse=True)[:limit]


def valid_png(path):
    """Decodes cleanly (ImageMagick); without it, trust the file."""
    if not shutil.which("magick"):
        return os.path.getsize(path) > 0
    return subprocess.run(["magick", path, "-regard-warnings", "null:"], capture_output=True).returncode == 0


def exe_icon(exe, slug):
    """The .exe's own icon as a PNG (largest size up to 256 px), cached; "wine" if it has none.
    A failed extraction leaves an empty file so it isn't retried every time."""
    png = f"{ICONS}/{slug}.png"
    if not os.path.exists(png):
        os.makedirs(ICONS, exist_ok=True)
        tmp = f"{ICONS}/{slug}.ico"
        ok = False
        if shutil.which("wrestool") and shutil.which("icotool"):
            # the started .exe first; Unreal-style starters often have no icon,
            # the real game binary deeper in the folder does
            for cand in [exe] + other_exes(exe):
                subprocess.run(["wrestool", "-x", "-t", "14", cand, "-o", tmp], capture_output=True)
                if not (os.path.exists(tmp) and os.path.getsize(tmp)):
                    continue
                sizes = re.findall(r"--index=(\d+) --width=(\d+)",
                                   subprocess.run(["icotool", "-l", tmp], capture_output=True, text=True).stdout)
                # largest size first; some .exe files carry a damaged image, try the next size
                for index, _w in sorted(sizes, key=lambda x: -int(x[1])):
                    ok = (subprocess.run(["icotool", "-x", "-i", index, "-o", png, tmp], capture_output=True).returncode == 0
                          and valid_png(png))
                    if ok:
                        break
                if ok:
                    break
        if os.path.exists(tmp):
            os.remove(tmp)
        if not ok:
            open(png, "w").close()
    return png if os.path.getsize(png) else "wine"


def norm(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def all_games():
    games = list(steam_games())
    shortcuts = list(steam_shortcuts())
    games += shortcuts
    games += folder_games({exe for *_, exe in shortcuts}, {norm(g[0]) for g in games})
    stats = load_stats()
    # recently played first (newest on top), then the rest A-Z
    return sorted(games, key=lambda g: (-stats.get(g[0], {}).get("last", 0), g[0].lower()))


def load_stats():
    try:
        return json.load(open(STATE))
    except (OSError, ValueError):
        return {}


def mark_played(name):
    stats = load_stats()
    stats.setdefault(name, {})["last"] = int(time.time())
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE + ".tmp", "w") as f:
        json.dump(stats, f)
    os.replace(STATE + ".tmp", STATE)


def ago(ts):
    days = (time.time() - ts) / 86400
    if days < 1:
        return "today"
    if days < 2:
        return "yesterday"
    return f"{int(days)} days ago" if days < 30 else f"{int(days // 30)} months ago"


def subtitle(game, stats):
    name, _icon, cmd, _extra = game
    s = stats.get(name, {})
    parts = ["Steam" if cmd[0] == "steam" else "Windows"]
    if s.get("played", 0) >= 60:
        h = s["played"] / 3600
        parts.append(f"{h:.0f} h played" if h >= 1 else f"{s['played'] // 60} min played")
    if s.get("last"):
        parts.append(ago(s["last"]))
    return " · ".join(parts)


# Saves are the Windows install's own folders, so a game continues where it
# left off on either system. The Windows drive is mounted at /mnt/Windows
# (/etc/fstab). Both ways of starting a game on Linux use them: plain Wine
# (opening the .exe in Thunar uses ~/.wine) and this launcher (Proton, one
# prefix per game). Each prefix's save folders are links to the Windows ones;
# whatever a prefix had there first is moved to <prefix>/saves-before-link/
# (files Windows didn't have are copied over first), never deleted.
# Games added to Steam and started from Steam get the same links. Wine can
# reset ~/.wine's links when it updates the prefix. Links are (re)made at login
# (UserConfigs/Startup_Apps.lua), on every launcher start, or with
# `GameLauncher.py --share-saves`.
WINDOWS = "/mnt/Windows"
# extra arguments for a Windows game, by its prefix name (/mnt/Data/Games/.umu/<name>).
# -dx11: Unreal games default to DirectX 12, which Proton runs through vkd3d, slow on
# NVIDIA; DirectX 11 goes through DXVK and runs close to Windows speed
GAME_ARGS = {
    "psychonauts-2": ["-dx11"],
}
SAVE_DIRS = ["Documents", "Saved Games", "AppData/Roaming", "AppData/Local", "AppData/LocalLow"]
WINE_USER = f"{HOME}/.wine/drive_c/users/{os.environ.get('USER', 'user')}"


def windows_home():
    """The Windows user's folder: the profile used most recently (its NTUSER.DAT
    changes at every Windows login), found instead of written here so no account
    name lives in the repo."""
    users = f"{WINDOWS}/Users"
    profiles = [f"{users}/{name}" for name in os.listdir(users)
                if name != "Default" and not os.path.islink(f"{users}/{name}")
                and os.path.isfile(f"{users}/{name}/NTUSER.DAT")]
    return max(profiles, key=lambda profile: os.path.getmtime(f"{profile}/NTUSER.DAT"))


def share_saves(user):
    """user: a prefix's drive_c/users/<name> folder."""
    backup = f"{os.path.dirname(os.path.dirname(os.path.dirname(user)))}/saves-before-link"
    home = windows_home()
    for rel in SAVE_DIRS:
        target = f"{home}/{rel}"
        os.makedirs(target, exist_ok=True)
        path = f"{user}/{rel}"
        if os.path.islink(path):
            if os.path.realpath(path) == os.path.realpath(target):
                continue
            os.unlink(path)
        elif os.path.exists(path):
            # files the shared folder doesn't have yet (e.g. a first run's saves)
            # are copied over, never overwriting; then the folder goes to the backup
            # (folder links like Proton's Documents/Music are skipped: never saves,
            # and the Windows drive refuses them)
            # (Wine's own files can hit read-only Windows system folders: skipped,
            # they stay in the backup like everything else)
            try:
                shutil.copytree(path, target, dirs_exist_ok=True,
                                ignore=lambda d, names: [n for n in names if os.path.islink(os.path.join(d, n))],
                                copy_function=lambda src, dst: os.path.exists(dst) or shutil.copy2(src, dst))
            except shutil.Error:
                pass
            os.makedirs(f"{backup}/{os.path.dirname(rel)}", exist_ok=True)
            os.rename(path, f"{backup}/{rel}")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        os.symlink(target, path)


def share_all_saves():
    """False when the Windows drive isn't there (links would point nowhere and saves get lost)."""
    if not os.path.ismount(WINDOWS):
        return False
    users = [WINE_USER] + [f"{PREFIXES}/{d}/drive_c/users/steamuser" for d in os.listdir(PREFIXES)]
    # games added to Steam ("non-Steam games"): Steam gives them ids from 2^31 up,
    # real Steam games keep their own prefix (Steam Cloud handles those)
    for lib in steam_libraries():
        data = f"{lib}/steamapps/compatdata"
        if os.path.isdir(data):
            users += [f"{data}/{d}/pfx/drive_c/users/steamuser" for d in os.listdir(data)
                      if d.isdigit() and int(d) >= 2**31]
    for user in users:
        if os.path.isdir(user):   # new prefixes: after their first run
            share_saves(user)
    return True


def run_umu(args, env, name):
    """umu-run ARGS; while umu downloads a new Proton or Steam runtime first (one-time,
    minutes), a sticky flyout shows it (UmuDownload.sh finds the download). Returns the exit code."""
    proc = subprocess.Popen(["umu-run"] + args, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shown = False
    while proc.poll() is None:
        time.sleep(1)
        download = subprocess.run([DOWNLOAD], capture_output=True, text=True).stdout.split(maxsplit=1)
        if download:
            subprocess.run(["qs", "ipc", "call", "osd", "rich", "game", f"Downloading {download[1]}",
                            f"{download[0]} MB so far · one-time, then {name} starts",
                            json.dumps({"sticky": True})], capture_output=True)
            shown = True
        elif shown:
            subprocess.run(["qs", "ipc", "call", "osd", "dismissKind", "game"], capture_output=True)
            shown = False
    return proc.returncode


def prepare_prefix(name, prefix, env):
    """A new game's prefix is made before its first run, so its save folders can be
    linked to the Windows ones first (else the first run saves inside the prefix and
    doesn't see the Windows save). wineboot sets up the prefix in a few seconds."""
    if os.path.isdir(f"{prefix}/drive_c/users/steamuser"):
        return
    subprocess.run(["qs", "ipc", "call", "osd", "rich", "game", f"Setting up {name}",
                    "First launch: linking your Windows saves", json.dumps({"sticky": True})],
                   capture_output=True)
    run_umu(["wineboot", "-u"], env, name)


def gamepads_through_sdl(name, prefix, env):
    """Controllers reach games through SDL only, not also as raw HID devices. The 8BitDo
    Ultimate 2's 2.4 GHz dongle shows both ways and Proton then fails to create the gamepad
    ("failed to create device for SDL bus device"), so games saw no controller. Set once per
    prefix (the marker file); the 8BitDo config app keeps raw HID in its own prefix."""
    marker = f"{prefix}/.gamepads-through-sdl"
    if os.path.exists(marker):
        return
    if run_umu(["reg", "add", r"HKLM\System\CurrentControlSet\Services\winebus",
                "/v", "DisableHidraw", "/t", "REG_DWORD", "/d", "1", "/f"], env, name) == 0:
        open(marker, "w").close()


def launch(game, gamescope=False, hud=False):
    name, icon, cmd, extra = game
    mark_played(name)
    env, cwd = dict(os.environ), None
    env["GAME_ICON"] = icon if icon.startswith("/") else ""
    if cmd[0] == "umu-run":
        if subprocess.run(["sh", "-c", "command -v umu-run"], capture_output=True).returncode:
            notify("Install umu-launcher to run this game: sudo pacman -S umu-launcher")
            return
        exe, slug = extra
        prefix = f"{PREFIXES}/{slug}"
        os.makedirs(prefix, exist_ok=True)
        env.update(WINEPREFIX=prefix, GAMEID="umu-default")
        cwd = os.path.dirname(exe)
        rom = switch_rom(exe)
        if not (rom and gamescope and eden_installed()):
            prepare_prefix(name, prefix, env)
            gamepads_through_sdl(name, prefix, env)
        if not share_all_saves():
            notify(f"Windows drive isn't mounted at {WINDOWS}: not starting, the game couldn't save")
            return
        if rom and gamescope and eden_installed():
            # Switch game: native Eden, fullscreen (its own window, no gamescope);
            # Alt+Enter (gamescope=False) keeps the Windows emulator
            cmd = [RUN] + (["--hud"] if hud else []) + [name] + EDEN + ["-f", "-g", rom]
        else:
            cmd = [RUN] + (["--gamescope"] if gamescope else []) + (["--hud"] if hud else []) + [name, "umu-run", exe] + GAME_ARGS.get(slug, [])
    subprocess.Popen(cmd, env=env, cwd=cwd, start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if cmd[0] == "steam":   # Windows/Switch games say hello through GameRun.sh
        line = subprocess.run([os.path.expanduser("~/.config/hypr/scripts/Pack.sh"), "quip", "gameStart"],
                              capture_output=True, text=True).stdout.strip() or "Starting {game}"
        subprocess.run(["qs", "ipc", "call", "osd", "rich", "game", line.replace("{game}", name), "Steam",
                        json.dumps({"image": icon} if icon.startswith("/") else {})], capture_output=True)


def menu_toggle(name):
    """Same as UserScripts/menu-toggle.sh: pressing the key again closes the menu."""
    state = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "rofi-menu")
    if subprocess.run(["pidof", "-q", "rofi"]).returncode == 0:
        try:
            open_name, pid = open(state).read().split()
        except (OSError, ValueError):
            open_name, pid = "", "0"
        subprocess.run(["pkill", "-x", "rofi"])
        try:
            os.kill(int(pid), 0)
            alive = True
        except (OSError, ValueError):
            alive = False
        if open_name == name and alive:
            return False
    with open(state, "w") as f:
        f.write(f"{name} {os.getpid()}\n")
    return True


def main():
    if "--share-saves" in sys.argv:
        sys.exit(0 if share_all_saves() else f"{WINDOWS} isn't mounted")
    if "--list" not in sys.argv and not menu_toggle("games"):
        return
    games = all_games()
    if "--list" in sys.argv:
        for name, _icon, cmd, extra in games:
            print(f"{name} | {' '.join(cmd)}" + (f" | prefix {extra[1]}" if cmd[0] == "umu-run" else ""))
        return
    if not games:
        notify("No games found")
        return
    stats = load_stats()
    rows = "\n".join(
        f"{html.escape(g[0])}  <span size='small' alpha='55%'>{html.escape(subtitle(g, stats))}</span>"
        f"\0icon\x1f{g[1]}\x1fmeta\x1f{html.escape(g[0])}"
        for g in games)
    res = subprocess.run(["rofi", "-dmenu", "-i", "-p", "Games", "-show-icons", "-markup-rows",
                          "-format", "i", "-kb-custom-1", "Alt+Return",
                          "-kb-accept-alt", "Control+Alt+Return", "-kb-custom-2", "Shift+Return",
                          "-mesg", "Enter: play (Windows games in gamescope)   ·   Alt+Enter: without gamescope   ·   Shift+Enter: FPS overlay shown (Alt+R in game toggles it)"],
                         input=rows, capture_output=True, text=True)
    # exit 0: Enter (gamescope), 10: Alt+Enter (no gamescope), 11: Shift+Enter (gamescope + FPS overlay)
    if res.returncode in (0, 10, 11) and res.stdout.strip().isdigit():
        launch(games[int(res.stdout.strip())], gamescope=res.returncode != 10, hud=res.returncode == 11)


if __name__ == "__main__":
    main()
