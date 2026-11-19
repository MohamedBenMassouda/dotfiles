# CLAUDE.md: dotfiles for Arch + Hyprland 0.57 (Lua) + Quickshell

Personal desktop of one user (`monarch`), GitHub `MohamedBenMassouda/dotfiles` (public).
Started from JaKooLit's Hyprland-Dots, heavily reworked: Waybar/swaync are gone, the whole
shell (bar, flyouts, notifications, panels, lock, overview, desktop mascot) is Quickshell/QML.

## Rules for working here

- **Commits:** many small conventional commits, `type(scope): lowercase message`
  (`feat(bar): …`, `fix(greeter): …`, `perf(packs): …`). Authored as the user. **Never add a
  Co-Authored-By or any Claude/AI attribution.** Commit as you go; **push only when asked.**
- **The repo is public:** never commit secrets, and never commit media the user doesn't own
  (e.g. ripped game/movie sounds go in `~/.local/share/sounds/desktop/`, outside the repo).
- **The user is live on this desktop.** While testing, don't switch their workspace, move their
  pointer, open windows on their screen or restart audio without saying so first. Use
  `grim` screenshots, `qs log`, preview modes and throwaway copies (`HOME=<scratch dir>`).
- **Sudo is the user's:** you can't run it. Hand over exact commands as `! sudo …`, or put
  system files in `system/` with an install line.
- **User-visible text** (flyouts, README, comments) is plain English, no jargon. Comments
  explain *why* and point to the related file.
- Prefer the smallest change that works; reuse what exists (helpers below) before writing new.

## Layout

```
bootstrap.sh          fresh install: questions → yay → packages.txt groups → stow → services
                      (--check lists links/conflicts; conflicting files go to ~/dotfiles-backup/<date>/)
packages.txt          [core] + optional [groups]; flatpaks.txt for Flathub apps
.stow-local-ignore    repo files NOT linked into ~ (README, CLAUDE.md, greeter/, system/, …)
greeter/              greetd login screen: Quickshell inside its own Hyprland (install: sudo greeter/install.sh)
system/               files for /etc (udev rules…); never stowed, installed by hand
.config/hypr/         Hyprland (Lua) + all shell scripts
.config/quickshell/   the desktop shell (QML)
.config/wallust/      colour templates (wallpaper → colours for hypr, rofi, quickshell, kitty, gtk, firefox)
.config/wireplumber/  audio rules (wireplumber.conf.d/5x-*.conf)
.config/systemd/user/ quickshell.service
.config/autostart/    Hidden=true overrides for XDG autostart apps the bar replaces (nm-applet,
                      print-applet; blueman stays: it answers Bluetooth pairing prompts)
.config/uwsm/env      session environment
.local/share/applications/  desktop entry overrides
.zshrc .tmux.conf     shell (the Neovim config is a separate repo, cloned by bootstrap)
```

Deploy = GNU stow from the repo root: `stow -n -v -t ~ .` (dry run), `stow -t ~ .`.
`~/.config/hypr`, `~/.config/quickshell` are links into the repo, so edits are live.
New files in already-real dirs (e.g. `~/.config/systemd/user`) need a `stow -t ~ .` run.

## Hyprland 0.57, Lua config

- Entry `hyprland.lua` requires `configs/*` (defaults) then `UserConfigs/*` (overrides win),
  plus `monitors.lua`/`workspaces.lua` (nwg-displays). `01-UserDefaults.conf` holds
  `term`/`files` read by `lib.lua`.
- `lib.lua` helpers: `lib.bind(keys, description, dispatcher, opts)` (the description feeds
  the `SUPER+K` cheat sheet), `lib.app(cmd)` (uwsm-aware launch), `lib.scriptsDir`,
  `lib.UserScripts`, `lib.uwsm`, `lib.term`. Use `hl.dsp.exec_cmd(...)` for commands.
- API: `hl.bind`, `hl.window_rule({match={class=...}, float=true, ...})`,
  `hl.layer_rule`, `hl.workspace_rule`, `hl.animation`, `hl.curve`, `hl.config({...})`,
  `hl.env`, `hl.on("workspace.created", fn)`, `hl.device`, `hl.monitor`.
  Dispatch from shell: `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`,
  `hyprctl eval '<lua>'`, `hyprctl repl 'hl.get_config("animations.enabled")'`.
  Switch binds: `bind("switch:on:Lid Switch", …)`.
- css_gap values must be a table or int, e.g. `gaps_out = { top=90, bottom=90, left=170, right=170 }`.
- **Verify every edit:** `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`, then
  `hyprctl reload` and `hyprctl configerrors`.
- Layer rule `namespace = "quickshell"` (blur) matches any namespace *containing*
  "quickshell". Full-screen layers that move (desktop mascot) use other names
  (`desktop-mascot`, `spider-tracer`) so they don't get blurred every frame.

## Quickshell (`.config/quickshell`)

`shell.qml` instantiates: per-screen `Bar`, `DesktopMascot`, `Tracer`, plus `Osd`, and,
lazily (`LazyLoader`, built only while open), `Overview`, `ControlCenter`, `NotificationCenter`.
`lock.qml` runs as a **separate process** (`hypr/scripts/QsLock.sh`), with its own singletons.

Singletons: `Theme` (colours from wallust `colors.json`, fonts, sizes), `Globals` (shared state,
processes, calendar, focus timer, controllers…), `Notifs`, `Icons`, `Pack` (theme packs).

**IPC** (`qs ipc call <target> <fn> …`; a function named `show` clashes with `qs ipc show`):

| target | functions |
|---|---|
| `osd` | `volume` `media` `mic` `brightness <pct>` `keyboard <pct>` `toast <kind> <title> <sub>` `rich <kind> <title> <sub> '<json>'` `hide` `dismissKind <kind>` |
| `panel` | `toggle control\|notifications` `dnd` `clearNotifications` `clearApp <app>` `pack` `suit` `packPaused <bool>` |
| `bar` / `overview` | `toggle` |
| `tracer` | `fire` |

The **flyout** (`Osd.qml`) is the notification surface for everything. `kinds` maps a kind
to icon + colour (unknown kinds get a bell). `rich` JSON fields: `image` (path),
`colors` (palette strip), `actions` (`[{label, glyph, cmd:[argv], then:[kind,title,sub]}]`),
`timeout` (ms), `sticky` (stays until `dismissKind`/click). Kinds in `senseKinds` trigger the
pack's spider-sense effect and the error sound. Scripts fall back to `notify-send` when `qs` fails.

QML gotchas met here:
- Qt's JS has no `Object.fromEntries`; avoid newer JS APIs.
- Binding loops (e.g. a width that depends on itself): compute imperatively
  (`Connections` + `Qt.callLater`).
- `Loader` can't take `implicitWidth`: set `width`/`height`, or let it follow `item`.
- Files loaded through `Loader` by URL (pack QML) are cached: after editing them,
  restart the shell (`systemctl --user restart quickshell.service`, or
  `pkill -x qs; hyprctl dispatch 'hl.dsp.exec_cmd("qs")'` when not under uwsm).
  Other QML files hot-reload; check `qs log` for `Configuration Loaded` / errors.
- Don't put `id: left`/`right` on items (clashes with anchors).
- Full-screen transparent layers cost a redraw per frame: keep them small (`implicitHeight`),
  animate in steps, set `mask: Region { item: … }` so clicks pass through.

## Theme packs (`quickshell/packs/<name>/`, `Pack.qml`)

Chosen pack in `~/.local/state/desktop-pack` (`none` = plain; no file = `spiderman`), suit in
`~/.local/state/desktop-pack-suit`. Game mode pauses packs via `$XDG_RUNTIME_DIR/desktop-pack-paused`
(`hypr/scripts/Pack.sh pause|resume`). A pack has `pack.json` (title, colour, feature flags
`buttonMascot workspaceMascot desktopMascot corners lockEmblem warningTingle notificationDrop`,
`hanger`, `crawler`, `suits {name:{title, colors}}`, `greeting`/`terminal` lines with `%u %h`,
`quips {kind:[lines]}`) and QML drawings: `Mascot.qml` (facing up, `color`), `Corner.qml`
(`corner` 0-3), `Emblem.qml` (`open`), `Hanger.qml`/`Crawler.qml` (pixel art, `pose`, `attachX`),
plus `sounds/`. Read in QML with `Pack.flag(key)`, `Pack.url(file)`, `Pack.quip(kind)`,
`Pack.suitColors`; in shell with `Pack.sh [dir|text KEY|quip KIND]`.
All Spider-Man art and lines in the repo were drawn/written for this repo. Keep it that way:
no copied artwork or film dialogue.

## Scripts (`hypr/scripts`, `hypr/UserScripts`), the ones that matter

- `Power.sh logout|reboot|poweroff`: hyprshutdown in its own systemd unit (started inside
  Hyprland it gets killed with it → black screen). Used by keybinds, power menu, updates.
- `ArchUpdate.py`: Arch news first, `yay -Syu`, then a flyout (restart button for kernel/driver).
- `GameLauncher.py` (SUPER+CTRL+G) + `GameRun.sh`: Steam, Steam shortcuts, Windows games in
  `/mnt/Data/Games` via umu-run (prefix per game in `/mnt/Data/Games/.umu/<slug>`; saves of
  prefixes and `~/.wine` link to the Windows user folders on `/mnt/Windows`, fstab), Switch games in the Eden Flatpak.
  Per-game options (gamescope, MangoHud, launch args like `-dx11`) live in
  `~/.local/state/game-launcher.json` (`options`), never in code (the repo is public): Enter plays
  with them, Alt+Enter / Shift+Enter flip gamescope / MangoHud and remember, Ctrl+O edits.
  `GAMEID=umu-<Steam app ID>` (protonfixes + Proton's per-app tweaks): app ID from Ctrl+O, else
  a `steam_appid.txt` in the folder (480 = Spacewar placeholder, ignored), else Steam's store
  search by name; cached as `appid` in the state file ("" = none found, `umu-default`).
  GameRun: game mode, gamemoderun, sticky loading flyout until the game's window appears
  (also shows umu downloading a new Proton via `UmuDownload.sh`, and low video memory with a
  button to close Discord/browsers), playtime in the same state file. `--list` prints what it finds.
- Training is **rep**, a separate repo (`/mnt/Data/Programming/Python/rep`, installed with
  `uv tool install`, its own CLAUDE.md). Here only the Training tile in `ControlCenter.qml`
  calls `~/.local/bin/rep`, and `~/.config/rep/config.toml` (not in this repo, holds personal
  data) sets `line_command = "~/.config/hypr/scripts/Pack.sh quip {kind}"` for pack lines.
- `ControllerDesk.py`: couch mode (controller drives the desktop when no game; Home = game
  launcher; View+Menu toggles). Needs python-evdev; reads devices without grabbing.
- `BtWatch.sh` (login): Bluetooth off/on + reconnect when the Realtek chip logs
  "Function not implemented (38)".
- `PlayerVolume.sh` (login): saves Spotifast's MPRIS volume (`~/.local/state/spotifast-volume`)
  and restores it when Spotifast starts at 100% (its Soloist player always does).
- `Controllers.sh watch`, `Runaway.sh`, `Usb.sh watch`, `Lid.sh`, `CmdDone.sh` (zsh hook for
  long commands), `Sounds.sh`, `Pack.sh`, `BtProfile.sh`, `GameMode.sh`, `WallustSwww.sh`.
- Menus are rofi (`UserScripts/*Menu.sh`, `applet.sh` helpers, `menu-toggle.sh` so the same key closes).

## Machine facts

- HP laptop: Intel UHD + **NVIDIA GTX 1650 Ti (desktop runs on NVIDIA:** `AQ_DRM_DEVICES`
  in `UserConfigs/ENVariables.lua`, switch with `UserScripts/GpuPrimary.sh`). eDP-1 1920x1080
  @1.25 + HDMI-A-1 1920x1080 (NVIDIA port). `nvidia-open`.
- Audio: Realtek ALC285 (one capture + one playback path; speakers/jack and internal/jack mic
  are ports of one device, renamed "Laptop speakers / headphone jack", "Laptop mic / headset jack").
  Bluetooth: **Realtek RTL8822CU (0bda:b00c)**. mSBC calls need USB autosuspend off
  (`system/udev/50-bluetooth-no-autosuspend.rules`). Headphones: Sony WH-CH720N
  (A2DP AAC by default, auto headset mode while mic in use, `wireplumber.conf.d/51-…`).
  Bluetooth mics have low priority (`53-…`) so they never become default on connect.
- Controller: 8BitDo Ultimate 2, Bluetooth or its 2.4 GHz dongle (xpad). In Proton the dongle
  shows as raw HID and SDL and winebus fails to create the gamepad, so `GameLauncher.py` sets
  winebus `DisableHidraw=1` once per prefix (marker `.gamepads-through-sdl`). Over Bluetooth
  UPower reports its battery.
- Session: greetd + Quickshell greeter → "Hyprland (uwsm-managed)". Under uwsm, Quickshell is
  `quickshell.service` (auto-restart); outside uwsm (TTY login / crash restart) it's a plain `qs`.
  `Startup_Apps.lua` avoids starting a second bar either way.
- `/etc/hosts` must contain `127.0.1.1 archlinux`: without it Proton waits ~20 s per launch
  (DNS timeout inside the Steam runtime).
- Flathub is set up for the user (`flatpak --user`). The 8BitDo config app (Windows) runs under
  Proton from `~/Applications/8BitDo` (needs `PROTON_ENABLE_HIDRAW=1`); never flash firmware through it.

## Shell pitfalls (zsh is the login shell)

- zsh doesn't word-split `$var`; use arrays or `bash -c` for word-split lists.
- Unmatched globs abort the whole command in zsh.
- `pkill -f PATTERN` matches the running command line itself (exit 144, kills your shell):
  use `pgrep -x name`, exact PIDs, or a pattern that doesn't occur in the command.
- `hostname` isn't installed; read `/etc/hostname`.
- Bash `$(…)` strips NUL bytes: pipe rofi rows (`\0icon\x1f…`) straight into rofi.

## System-side setup (done on this machine; repeat on a fresh install)

`sudo greeter/install.sh` (greeter + keyring unlock + sync unit),
`sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service`
(without them Hyprland crashes on resume), `sudo cp system/udev/*.rules /etc/udev/rules.d/`,
`127.0.1.1 archlinux` in `/etc/hosts`, then `sudo bash system/finish-setup.sh` (idempotent):
game mode's CPU cap (`tmpfiles.d/`), package cache trim, waybar removal.
Snapshots: Timeshift (btrfs mode, weekly, excludes /home) + `timeshift-autosnap` before every
pacman transaction; `grub-btrfsd --timeshift-auto` lists them in GRUB. `/boot` is FAT, so
kernels aren't in snapshots.
