#!/usr/bin/env bash
# One-time system steps that need root. Safe to run again: each step checks first.
#   sudo bash ~/dotfiles/system/finish-setup.sh
#
# 1. Game mode's CPU cap rule (tmpfiles.d/cpu-game-cap.conf, used by hypr/scripts/Pack.sh).
# 2. Package cache: keep only the previous version of each package.
# 3. Remove waybar, unused since the bar moved to Quickshell.
# 4. Show what holds the kernel's unreclaimable memory (for checking, changes nothing).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo bash $0"; exit 1; }
here=$(dirname "$(readlink -f "$0")")

step() { printf '\n== %s\n' "$*"; }

step "1. Game mode CPU cap"
cp "$here/tmpfiles.d/cpu-game-cap.conf" /etc/tmpfiles.d/
systemd-tmpfiles --create /etc/tmpfiles.d/cpu-game-cap.conf

step "2. Package cache"
pacman -S --needed --noconfirm pacman-contrib
paccache -rk1
paccache -ruk0

step "3. waybar"
pacman -Q waybar &>/dev/null && pacman -Rns --noconfirm waybar || echo "already removed"

step "4. Kernel memory (top 12, for checking)"
slabtop -o -s c | head -19 || true

echo
echo "Done. (System snapshots are Timeshift's: timeshift-autosnap before every update, listed in GRUB.)"
