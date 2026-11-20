#!/usr/bin/env bash
# One-time system steps that need root. Safe to run again: each step checks first.
#   sudo bash ~/dotfiles/system/finish-setup.sh
#
# 1. Game mode's CPU cap rule (tmpfiles.d/cpu-game-cap.conf, used by hypr/scripts/Pack.sh).
# 2. Package cache: keep only the previous version of each package.
# 3. Remove waybar, unused since the bar moved to Quickshell.
# 4. Show what holds the kernel's unreclaimable memory (for checking, changes nothing).
# 5. Weekly disk health check (disk-health/), shown at login by hypr/scripts/DiskHealth.sh.
# 6. Firmware: install fwupd and list available updates (installs nothing by itself).
# 7. systemd-oomd (oomd/): when RAM runs out, close the app using the most memory instead
#    of the whole desktop freezing; hypr/scripts/OomWatch.sh says which app it closed.
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

step "5. Disk health"
pacman -S --needed --noconfirm smartmontools jq
install -m 755 "$here/disk-health/disk-health.sh" /usr/local/bin/disk-health
install -m 644 "$here/disk-health/disk-health.service" "$here/disk-health/disk-health.timer" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now disk-health.timer
systemctl start disk-health.service
cat /var/lib/disk-health/status

step "6. Firmware updates available"
pacman -S --needed --noconfirm fwupd
fwupdmgr refresh --force >/dev/null 2>&1 || true
fwupdmgr get-updates || true
echo "To install them: fwupdmgr update   (laptop on the charger; a BIOS update restarts the laptop)"

step "7. Out-of-memory protection"
install -D -m 644 "$here/oomd/user-service-oomd.conf" /etc/systemd/system/user@.service.d/10-oomd.conf
install -D -m 644 "$here/oomd/root-slice-oomd.conf" /etc/systemd/system/-.slice.d/10-oomd.conf
install -D -m 644 "$here/oomd/oomd.conf" /etc/systemd/oomd.conf.d/10-desktop.conf
systemctl daemon-reload
systemctl enable --now systemd-oomd.service
oomctl | head -20

echo
echo "Done. (System snapshots are Timeshift's: timeshift-autosnap before every update, listed in GRUB.)"
