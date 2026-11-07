#!/usr/bin/env bash
# Set up this desktop on a fresh Arch install (run as your user, it uses sudo):
#   git clone https://github.com/MohamedBenMassouda/dotfiles ~/dotfiles
#   ~/dotfiles/bootstrap.sh          asks what to include, then installs
#   ~/dotfiles/bootstrap.sh --yes    no questions, take the defaults
#   ~/dotfiles/bootstrap.sh --check  only show which files it would link or move aside
# All questions come first, so you can leave it running afterwards.
# Safe to run again: packages are --needed, links already in place are skipped.
# Files already in the way of a link are moved to ~/dotfiles-backup/<date>/
# (same folder layout), never deleted.
set -euo pipefail
cd "$(dirname "$(realpath "$0")")"
dots=$PWD

assume_yes=false check=false
for arg in "$@"; do
  case $arg in
    --yes|-y) assume_yes=true ;;
    --check) check=true ;;
  esac
done

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# what stow would do: new links, and existing files in the way of one
stow_links()     { stow -n -v -t ~ . 2>&1 | sed -n 's/^LINK: \(.*\) => .*/\1/p'; }
stow_conflicts() { stow -n -v -t ~ . 2>&1 | sed -n 's/.*over existing target \(.*\) since.*/\1/p; s/.*existing target is neither a link nor a directory: \(.*\)/\1/p'; }
backup=~/dotfiles-backup/$(date +%Y-%m-%d_%H%M%S)

if $check; then
  echo "Would link into ~:"
  stow_links | sed 's/^/  /' | grep . || echo "  (nothing new, everything is linked already)"
  echo "Would move aside to $backup:"
  stow_conflicts | sed 's/^/  /' | grep . || echo "  (nothing)"
  exit 0
fi

# ---- questions ----------------------------------------------------------
declare -A want
# ask <key> <default y|n> <question>
ask() {
  local key=$1 def=$2 q=$3 hint reply
  [[ $def == y ]] && hint="Y/n" || hint="y/N"
  if $assume_yes; then
    reply=$def
  else
    read -rp "$(printf '\033[1m%s\033[0m [%s] ' "$q" "$hint")" reply
    reply=${reply:-$def}
  fi
  [[ ${reply,,} == y* ]] && want[$key]=1 || want[$key]=0
}
on() { [[ ${want[$1]:-0} == 1 ]]; }

echo "The desktop itself (Hyprland, Quickshell, rofi, wallust, kitty, zsh, tmux) is always installed."
echo "Choose the extras:"
echo

if systemctl is-enabled display-manager.service >/dev/null 2>&1; then
  want[greeter]=0
else
  ask greeter y "No login screen found. Install the Quickshell login screen (greetd)?"
fi
ask nvim y "Neovim and its config?"
ask dev y "Dev tools: Docker and lazygit (dev menu)?"
ask games y "Games: umu-launcher for Windows games?"

flatpaks=$(grep -vE '^\s*(#|$)' flatpaks.txt | tr '\n' ' ')
ask flatpak y "Flathub apps ($flatpaks)?"
picked_flatpaks=()
if on flatpak; then
  if $assume_yes; then
    read -ra picked_flatpaks <<<"$flatpaks"
  else
    read -rp "  Install all of them, or pick one by one? [A/p] " how
    for app in $flatpaks; do
      if [[ ${how,,} == p* ]]; then
        read -rp "    $app? [Y/n] " r
        [[ ${r:-y} == [yY]* ]] || continue
      fi
      picked_flatpaks+=("$app")
    done
  fi
fi

ask firefox y "Colour Firefox from the wallpaper (Pywalfox)?"
ask firewall y "Firewall (ufw: KDE Connect, LocalSend, Spotify only from your LAN)?"
if [[ $(findmnt -no FSTYPE /) == btrfs && -d /boot/grub ]]; then
  ask snapshots y "Snapshots before every update + in the GRUB menu (Timeshift)?"
else
  want[snapshots]=0
fi
if [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]]; then
  ask zsh y "Make zsh your login shell?"
else
  want[zsh]=0
fi

# ---- install ------------------------------------------------------------
step "yay (AUR helper)"
if ! command -v yay >/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi

step "Packages"
# core packages + every group you said yes to ([group] lines in packages.txt)
groups=" core "
for g in "${!want[@]}"; do on "$g" && groups+="$g "; done
awk -v groups="$groups" '
  BEGIN { g = "core" }
  /^\[.*\]$/ { g = substr($0, 2, length($0) - 2); next }
  /^[[:space:]]*(#|$)/ { next }
  index(groups, " " g " ") { print $1 }
' packages.txt | yay -S --needed -

if on flatpak && (( ${#picked_flatpaks[@]} )); then
  step "Flatpak apps"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y --noninteractive flathub "${picked_flatpaks[@]}"
fi

if on nvim; then
  step "Neovim config"
  # its own repo, cloned straight into place (an existing one is left alone)
  [[ -e ~/.config/nvim ]] || git clone https://github.com/MohamedBenMassouda/nvim ~/.config/nvim
fi

step "Link configs into ~ with stow"
# a fresh install has default files (e.g. ~/.zshrc): move them into one backup
# folder instead of failing (they stay there, nothing is deleted)
moved=0
while read -r target; do
  if [[ -e ~/$target && ! -L ~/$target ]]; then
    mkdir -p "$backup/$(dirname "$target")"
    mv -v ~/"$target" "$backup/$target"
    moved=$((moved + 1))
  fi
done < <(stow_conflicts)
stow -v -t ~ .
(( moved )) && echo "Moved $moved existing file(s) out of the way: $backup"

step "Services"
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon paccache.timer
if on greeter; then
  sudo "$dots/greeter/install.sh"
  sudo systemctl enable greetd
fi
if on dev; then
  sudo systemctl enable docker
  sudo usermod -aG docker "$USER"
fi

if on firewall; then
  step "Firewall"
  "$dots/.config/hypr/scripts/SetupFirewall.sh"
fi

if on snapshots; then
  step "Snapshots"
  "$dots/.config/hypr/scripts/SetupSystem.sh"
fi

if on zsh; then
  step "Login shell: zsh"
  chsh -s /usr/bin/zsh
fi

step "Colours (wallust) from a wallpaper"
# GTK apps: adw-gtk3 theme, coloured by wallust (gtk-3.0/4.0 colors.css)
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.cache/wal
[[ -f ~/.config/gtk-3.0/gtk.css ]] || echo "@import 'colors.css';" > ~/.config/gtk-3.0/gtk.css
[[ -f ~/.config/gtk-4.0/gtk.css ]] || echo "@import 'colors.css';" > ~/.config/gtk-4.0/gtk.css
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

# Firefox: Pywalfox reads ~/.cache/wal/colors.json (written by wallust)
on firefox && pywalfox install

wall=$(find ~/Pictures/wallpapers -type f \( -name '*.png' -o -name '*.jpg' \) 2>/dev/null | head -1 || true)
if [[ -n $wall ]]; then
  ln -sf "$wall" ~/.config/rofi/.current_wallpaper
  wallust run "$wall" || true
else
  echo "No wallpapers in ~/Pictures/wallpapers yet: add some, then pick one with SUPER+W."
fi

step "Done"
echo "Log out and pick \"Hyprland (uwsm-managed)\" on the login screen. Keybinds: SUPER+K, or README.md."
on firefox && echo "Firefox: install the Pywalfox add-on (addons.mozilla.org), then click \"Fetch Pywal colors\"."
on dev && echo "Docker: log out and back in once so your user can run docker without sudo."
exit 0
