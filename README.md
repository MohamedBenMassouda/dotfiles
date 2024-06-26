# Dotfiles
This is my current dotfiles using Hyprland in Fedora 38.

### What Do I use?
- zsh (Shell)
- nvim (Text Editor)
- fzf (Fuzzy Finder)
- tmux (Terminal Multiplexer)
- fd (Better alternative to find)
- ripgrep (Better and Faster grep)
- hyprland (Tiling Window Manager)
- swaync (Notification deamon)
- rofi (Launcher)
- clipman (Clipboard Manager)

### Installation
#### Requirements
I'm using Fedora so I use `dnf` as my package manager. <br>
Also I installed hyprland using this [repo](https://github.com/JaKooLit/Fedora-Hyprland) from [JaKooLit](https://github.com/JaKooLit).<br>

#### Needed coprs
```
alebastr/sway-extras
cyqsimon/fzf
en4aew/desktop-tools
erikreider/SwayNotificationCenter
phracek/PyCharm
solopasha/hyprland
trs-sod/swaylock-effects
zeno/scrcpy
```

```bash
sudo dnf install zsh stow git fzf tmux neovim fd-find ripgrep rofi-wayland SwayNotificationCenter hyprshot hyprlock hypridle wl-clipboard swww wlogout
```
```bash
mkdir ~/Git && cd ~/Git && git clone https://github.com/MohamedBenMassouda/clipman
cd clipman && go build
```

