#!/usr/bin/env bash
# One-time setup of the parts that need root. Run it yourself in a terminal
# (it asks for your sudo password):
#   ~/.config/hypr/scripts/SetupSystem.sh
#
#  1. OCR for "copy text from screen" (SUPER+SHIFT+T): tesseract + English data
#  2. Snapshots: Timeshift (already set up in btrfs mode) snapshots before every
#     pacman/yay update (timeshift-autosnap), its weekly schedule actually runs
#     (cronie was off), and snapshots show up in the GRUB menu (grub-btrfs) so
#     you can boot one if an update breaks something.
#  3. /etc/fstab: drops the fixed "subvolid=" numbers. A Timeshift restore
#     creates a new @ with a new id, and the old id would stop it from mounting.
#     A backup is kept in /etc/fstab.before-timeshift.
set -euo pipefail

echo "==> Packages"
yay -S --needed tesseract tesseract-data-eng timeshift-autosnap grub-btrfs inotify-tools cronie

echo "==> Timeshift schedule (cron)"
sudo systemctl enable --now cronie

echo "==> grub-btrfs: follow Timeshift's snapshots"
sudo mkdir -p /etc/systemd/system/grub-btrfsd.service.d
printf '[Service]\nExecStart=\nExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto\n' |
  sudo tee /etc/systemd/system/grub-btrfsd.service.d/timeshift.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now grub-btrfsd

echo "==> fstab: mount subvolumes by name only"
if grep -q 'subvolid=' /etc/fstab; then
  sudo cp /etc/fstab /etc/fstab.before-timeshift
  sudo sed -i -E 's/,subvolid=[0-9]+//' /etc/fstab
  if ! sudo findmnt --verify --tab-file /etc/fstab >/dev/null; then
    echo "fstab check failed, restoring the backup"
    sudo cp /etc/fstab.before-timeshift /etc/fstab
    exit 1
  fi
fi

echo "==> First snapshot + GRUB menu"
sudo timeshift --create --comments "after desktop setup" --tags D
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Done. Snapshots: sudo timeshift --list  (or the Timeshift app)."
