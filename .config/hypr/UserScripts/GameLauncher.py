#!/usr/bin/env python3
"""Rofi game launcher (SUPER+CTRL+G).

Lists, sorted by name:
  - installed Steam games (every Steam library)    -> launched through Steam
  - non-Steam games added to Steam                 -> launched through Steam (keeps their Proton prefix)
  - Windows games in /mnt/Data/Games                -> launched with Proton via umu-run,
                                                      one prefix per game in /mnt/Data/Games/.umu/

`GameLauncher.py --list` prints what was found instead of opening rofi.
"""
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
STEAM = f"{HOME}/.local/share/Steam"
GAMES_DIR = "/mnt/Data/Games"
PREFIXES = f"{GAMES_DIR}/.umu"
SKIP_DIRS = {"GameSaves"}
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
                yield name.group(1), "steam", ["steam", f"steam://rungameid/{appid.group(1)}"], None


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
        yield clean(entry.name), "wine", ["umu-run", exe], (exe, slug)


def norm(name):
    return re.sub(r"[^a-z0-9]", "", name.lower())


def all_games():
    games = list(steam_games())
    shortcuts = list(steam_shortcuts())
    games += shortcuts
    games += folder_games({exe for *_, exe in shortcuts}, {norm(g[0]) for g in games})
    return sorted(games, key=lambda g: g[0].lower())


def launch(game):
    name, _icon, cmd, extra = game
    env, cwd = dict(os.environ), None
    if cmd[0] == "umu-run":
        if subprocess.run(["sh", "-c", "command -v umu-run"], capture_output=True).returncode:
            notify("Install umu-launcher to run this game: sudo pacman -S umu-launcher")
            return
        exe, slug = extra
        prefix = f"{PREFIXES}/{slug}"
        os.makedirs(prefix, exist_ok=True)
        env.update(WINEPREFIX=prefix, GAMEID="umu-default")
        cwd = os.path.dirname(exe)
    subprocess.Popen(cmd, env=env, cwd=cwd, start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    notify(f"Starting {name}")


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
    rows = "\n".join(f"{name}\0icon\x1f{icon}" for name, icon, *_ in games)
    res = subprocess.run(["rofi", "-dmenu", "-i", "-p", "Games", "-show-icons", "-format", "i"],
                         input=rows, capture_output=True, text=True)
    if res.returncode == 0 and res.stdout.strip().isdigit():
        launch(games[int(res.stdout.strip())])


if __name__ == "__main__":
    main()
