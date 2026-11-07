#!/usr/bin/env bash
# Install the login screen: greetd + a Quickshell greeter that runs in its own
# small Hyprland with your monitor layout. Run from your user with sudo:
#   sudo ~/dotfiles/greeter/install.sh
# It does not switch login managers by itself; it prints the commands for that.
# Undo: sudo systemctl disable greetd && sudo systemctl enable gdm
set -euo pipefail
[[ $EUID -eq 0 && -n ${SUDO_USER:-} ]] || { echo "Run it with sudo from your user: sudo $0"; exit 1; }
user=$SUDO_USER
home=$(getent passwd "$user" | cut -d: -f6)
here=$(dirname "$(realpath "$0")")

echo "==> greeter-sync"
install -Dm755 "$here/greeter-sync.sh" /usr/local/bin/greeter-sync

echo "==> /etc/greetd/config.toml (old one kept as config.toml.orig)"
[[ -f /etc/greetd/config.toml && ! -f /etc/greetd/config.toml.orig ]] && cp /etc/greetd/config.toml /etc/greetd/config.toml.orig
cat > /etc/greetd/config.toml <<CONF
# Login screen: greeter/ in the dotfiles (installed by greeter/install.sh)
[terminal]
vt = 1

[default_session]
command = "/etc/greetd/greeter/start-greeter.sh"
user = "greeter"
CONF

echo "==> keep the login screen in sync (monitors, colours, wallpaper)"
# watch the real files behind the dotfiles links
watch=(
  "$(realpath "$home/.config/hypr/monitors.lua")"
  "$(realpath "$home/.config/quickshell/colors.json")"
  "$(realpath "$here/quickshell/GreeterScreen.qml")"
  "$(realpath "$here/quickshell/shell.qml")"
  "$(realpath "$here/hyprland.lua")"
)
cat > /etc/systemd/system/greeter-sync.service <<UNIT
[Unit]
Description=Copy monitor layout, colours and wallpaper to the login screen

[Service]
Type=oneshot
ExecStart=/usr/local/bin/greeter-sync $user
UNIT
{
  echo "[Unit]"
  echo "Description=Update the login screen when the desktop's monitors or colours change"
  echo
  echo "[Path]"
  for f in "${watch[@]}"; do echo "PathChanged=$f"; done
  echo
  echo "[Install]"
  echo "WantedBy=multi-user.target"
} > /etc/systemd/system/greeter-sync.path
systemctl daemon-reload
systemctl enable --now greeter-sync.path
/usr/local/bin/greeter-sync "$user"

cat <<DONE

Installed. To switch from your current login screen to this one:
  sudo systemctl disable gdm && sudo systemctl enable greetd
then reboot. If anything goes wrong you get a text login (or press Ctrl+Alt+F2),
and switching back is:
  sudo systemctl disable greetd && sudo systemctl enable gdm
DONE
