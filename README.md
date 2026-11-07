# Dotfiles

Arch Linux + Hyprland 0.57 (Lua config), with a Quickshell desktop shell and rofi menus,
coloured from the wallpaper by wallust. Based on JaKooLit's Hyprland-Dots, heavily reworked.

## Install (fresh Arch)

```sh
git clone https://github.com/MohamedBenMassouda/dotfiles ~/dotfiles
~/dotfiles/bootstrap.sh          # asks what to include, then installs
~/dotfiles/bootstrap.sh --yes    # no questions, defaults
~/dotfiles/bootstrap.sh --check  # only list what it would link or move aside
```

The desktop itself (Hyprland, Quickshell, rofi, wallust, kitty, zsh, tmux) is always
installed. `bootstrap.sh` asks first about the extras: login screen (greetd + Quickshell), Neovim + config,
Docker / lazygit, games (umu), Flathub apps (all or one by one, see
[`flatpaks.txt`](flatpaks.txt)), Firefox theming, firewall, Timeshift snapshots
(btrfs + GRUB only) and zsh as login shell. Then it installs yay and
the chosen groups from [`packages.txt`](packages.txt), links the configs into `~` with
GNU stow (existing files are moved to `~/dotfiles-backup/<date>/`, never deleted; `--check` shows what would change), enables the services and
generates the colours. Log in to **Hyprland (uwsm-managed)**.

## What's where

| Path | What |
|---|---|
| `.config/hypr/hyprland.lua` | Hyprland entry point; `configs/` defaults, `UserConfigs/` my overrides |
| `.config/hypr/scripts`, `UserScripts` | Volume, brightness, media, recording, OCR, rofi menus… |
| `.config/quickshell` | Bar (`bar/`), flyout + notifications (`Osd.qml`, `Notifs.qml`), panels (`panels/`), lock screen (`lock.qml`), overview |
| `.config/rofi` | One theme (`config.rasi`), applets (`config-applet.rasi`) |
| `.config/wallust` | Colour templates for Hyprland, rofi and Quickshell |
| `.config/uwsm` | Session environment |
| `greeter/` | Login screen: greetd + Quickshell in its own Hyprland, on your monitor layout (`sudo greeter/install.sh`) |
| `.config/wireplumber` | Bluetooth headsets start on AAC; headset mode only while the mic is in use |
| `.config/kitty`, `.zshrc`, `.tmux.conf` | Terminal (the Neovim config is its own repo, cloned to `~/.config/nvim` by bootstrap) |


## Desktop

- **Bar** on every monitor: kanji workspaces (other monitor's faded), CPU/RAM, cava,
  taskbar, clock (hover: calendar + weather), privacy dots, recording / focus timers,
  now playing, tray, volume, mic, status pill (Wi-Fi, Bluetooth, phone, updates), keep-awake, battery.
- **Flyout** (top centre): volume, mic, brightness, media, toggles, and every notification.
- **Quick settings** (`SUPER+N` or the status pill), **notifications** (`SUPER+H` or the bell),
  **overview** (`SUPER+A`), **lock screen** (`CTRL+ALT+L`, falls back to hyprlock).

## Keybinds

`SUPER+K` shows them all in rofi.

<details>
<summary>Full list</summary>

| Keys | Action |
|---|---|
| `CTRL+ALT+Delete` | Log out |
| `CTRL+ALT+End` | Shut down |
| `CTRL+ALT+Home` | Restart |
| `CTRL+ALT+P` | Power menu |
| `CTRL+ALT+L` | Lock screen |
| `SUPER+Q` | Close window |
| `SUPER+SHIFT+Q` | Close window |
| `SUPER+F` | Fullscreen |
| `SUPER+M` | Maximize |
| `SUPER+SHIFT+F` | Toggle floating |
| `SUPER+ALT+R` | Refresh colours, rofi |
| `CTRL+SHIFT+W` | Refresh colours, rofi |
| `SUPER+SHIFT+E` | Emoji picker |
| `SUPER+S` | Web search (rofi) |
| `SUPER+SHIFT+B` | Toggle blur strength |
| `SUPER+SHIFT+G` | Game mode on/off |
| `SUPER+ALT+L` | Switch master/dwindle layout |
| `SUPER+H` | Notification panel |
| `SUPER+N` | Quick settings |
| `SUPER+SHIFT+M` | Online music (rofi) |
| `SUPER+W` | Choose wallpaper |
| `CTRL+ALT+W` | Random wallpaper |
| `SUPER+B` | Show/hide bar |
| `SUPER+CTRL+D` | Remove master |
| `SUPER+I` | Add master |
| `SUPER+CTRL+Return` | Swap with master |
| `SUPER+G` | Toggle window group |
| `ALT+Tab` | Next window in group |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMicMute` | Mute mic |
| `XF86AudioMute` | Mute |
| `XF86Sleep` | Suspend |
| `XF86RFKill` | Airplane mode |
| `XF86AudioPause` | Play/pause |
| `XF86AudioPlay` | Play/pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86AudioStop` | Stop media |
| `Caps_Lock` | Caps Lock flyout |
| `SUPER+Print` | Screenshot |
| `SUPER+SHIFT+Print` | Screenshot area |
| `SUPER+CTRL+Print` | Screenshot in 5s |
| `SUPER+ALT+Print` | Screenshot in 10s |
| `ALT+Print` | Screenshot active window |
| `SUPER+SHIFT+S` | Screenshot (hyprshot) |
| `SUPER+ALT+S` | Screenshot to clipboard |
| `SUPER+SHIFT+U` | Move window to scratch workspace |
| `SUPER+U` | Show/hide scratch workspace |
| `SUPER+` | Workspace 1 |
| `SUPER+SHIFT+` | Move window to workspace 1 |
| `SUPER+CTRL+` | Send window to workspace 1 (stay) |
| `SUPER+` | Workspace 2 |
| `SUPER+SHIFT+` | Move window to workspace 2 |
| `SUPER+CTRL+` | Send window to workspace 2 (stay) |
| `SUPER+` | Workspace 3 |
| `SUPER+SHIFT+` | Move window to workspace 3 |
| `SUPER+CTRL+` | Send window to workspace 3 (stay) |
| `SUPER+` | Workspace 4 |
| `SUPER+SHIFT+` | Move window to workspace 4 |
| `SUPER+CTRL+` | Send window to workspace 4 (stay) |
| `SUPER+` | Workspace 5 |
| `SUPER+SHIFT+` | Move window to workspace 5 |
| `SUPER+CTRL+` | Send window to workspace 5 (stay) |
| `SUPER+` | Workspace 6 |
| `SUPER+SHIFT+` | Move window to workspace 6 |
| `SUPER+CTRL+` | Send window to workspace 6 (stay) |
| `SUPER+` | Workspace 7 |
| `SUPER+SHIFT+` | Move window to workspace 7 |
| `SUPER+CTRL+` | Send window to workspace 7 (stay) |
| `SUPER+` | Workspace 8 |
| `SUPER+SHIFT+` | Move window to workspace 8 |
| `SUPER+CTRL+` | Send window to workspace 8 (stay) |
| `SUPER+` | Workspace 9 |
| `SUPER+SHIFT+` | Move window to workspace 9 |
| `SUPER+CTRL+` | Send window to workspace 9 (stay) |
| `SUPER+` | Workspace 10 |
| `SUPER+SHIFT+` | Move window to workspace 10 |
| `SUPER+CTRL+` | Send window to workspace 10 (stay) |
| `XF86KbdBrightnessDown` | Keyboard backlight down |
| `XF86KbdBrightnessUp` | Keyboard backlight up |
| `XF86MonBrightnessDown` | Screen brightness down |
| `XF86MonBrightnessUp` | Screen brightness up |
| `XF86TouchpadToggle` | Touchpad on/off |
| `SUPER+F6` | Screenshot |
| `SUPER+SHIFT+F6` | Screenshot area |
| `SUPER+CTRL+F6` | Screenshot in 5s |
| `SUPER+ALT+F6` | Screenshot in 10s |
| `ALT+F6` | Screenshot active window |
| `SUPER+Super_L` | App launcher (tap SUPER) |
| `SUPER+D` | App launcher |
| `SUPER+SHIFT+Return` | Dropdown terminal |
| `SUPER+Return` | Terminal |
| `SUPER+E` | File manager |
| `SUPER+SHIFT+O` | Change oh-my-zsh theme |
| `SUPER+SHIFT+D` | Color picker |
| `SUPER+SHIFT+T` | Copy text from screen (OCR) |
| `SUPER+CTRL+H` | Open Hyprland wiki |
| `SUPER+V` | Clipboard history |
| `SUPER+SHIFT+V` | Clipboard images |
| `ALT+Tab` | Next window |
| `ALT+SHIFT+Tab` | Previous window |
| `SUPER+L` | Lock screen |
| `SUPER+J` | Toggle focus-follows-mouse |
| `SUPER+K` | Keybind cheat sheet |
| `SUPER+SHIFT+W` | Random wallpaper |
| `SUPER+T` | Open project (tmux) |
| `SUPER+X` | Switch to window |
| `SUPER+ALT+A` | Audio output/input |
| `SUPER+CTRL+G` | Game launcher |
| `SUPER+A` | Workspace overview |
| `SUPER+P` | Media controls |
| `SUPER+SHIFT+P` | Screenshot menu |
| `SUPER+SHIFT+L` | Brightness menu |
| `SUPER+CTRL+R` | Recording menu |
| `SUPER+ALT+D` | Dev menu (containers, ports, lazygit) |
| `SUPER+ALT+G` | Switch primary GPU (next login) |
| `SUPER+ALT+P` | Cycle power profile |
| `SUPER+SHIFT+R` | Start/stop screen recording |
| `SUPER+ALT+H` | Connect/disconnect headphones |
| `SUPER+ALT+T` | Bluetooth manager |
| `SUPER+ALT+Right` | Next track |
| `SUPER+ALT+Left` | Previous track |
| `SUPER+ALT+X` | Stop media |
| `SUPER+ALT+Space` | Play/pause |
| `SUPER+ALT+Up` | Volume up |
| `SUPER+ALT+Down` | Volume down |
| `SUPER+C` | Show/hide System monitor (btop) |
| `SUPER+1…0` | Workspace 1–10 (`+SHIFT` move window, `+CTRL` send window and stay) |
| `SUPER+arrows` | Focus (`+SHIFT` resize, `+CTRL` move) |

</details>
