#!/usr/bin/env bash
# Set up this desktop on a fresh Arch install (run as your user, it uses sudo):
#   git clone --recurse-submodules https://github.com/MohamedBenMassouda/dotfiles ~/dotfiles
#   ~/dotfiles/bootstrap.sh
# Safe to run again: packages are --needed, links already in place are skipped.
set -euo pipefail
cd "$(dirname "$(realpath "$0")")"
dots=$PWD

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

step "yay (AUR helper)"
if ! command -v yay >/dev/null; then
  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi

step "Packages (packages.txt)"
grep -vE '^\s*(#|$)' packages.txt | yay -S --needed -

step "Flatpak apps (flatpaks.txt)"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
grep -vE '^\s*(#|$)' flatpaks.txt | xargs -r flatpak install -y --noninteractive flathub

step "Neovim config (submodule)"
git submodule update --init --recursive

step "Link configs into ~ with stow"
# a fresh install has default files (e.g. ~/.zshrc): move them aside instead of failing
while read -r target; do
  [[ -e ~/$target && ! -L ~/$target ]] && mv -v ~/"$target" ~/"$target.pre-dotfiles"
done < <(stow -n -v -t ~ . 2>&1 | sed -n 's/.*over existing target \(.*\) since.*/\1/p; s/.*existing target is neither a link nor a directory: \(.*\)/\1/p')
stow -v -t ~ .

step "Services"
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon cronie paccache.timer
# login screen, unless another one is already set up
systemctl is-enabled display-manager.service >/dev/null 2>&1 || sudo systemctl enable gdm
sudo systemctl enable docker
sudo usermod -aG docker "$USER"

step "Login shell: zsh"
[[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]] || chsh -s /usr/bin/zsh

step "Colours (wallust) from a wallpaper"
wall=$(find ~/Pictures/wallpapers -type f \( -name '*.png' -o -name '*.jpg' \) 2>/dev/null | head -1 || true)
if [[ -n $wall ]]; then
  ln -sf "$wall" ~/.config/rofi/.current_wallpaper
  wallust run "$wall" || true
else
  echo "No wallpapers in ~/Pictures/wallpapers yet: add some, then pick one with SUPER+W."
fi

cat <<'DONE'

Done. Log out and pick "Hyprland (uwsm-managed)" in your display manager.
Optional, btrfs + GRUB only: snapshots before updates and in the boot menu:
  ~/.config/hypr/scripts/SetupSystem.sh
Keybinds: SUPER+K, or see README.md.
DONE
