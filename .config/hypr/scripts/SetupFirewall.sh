#!/usr/bin/env bash
# Firewall (ufw): block everything coming in, except what this desktop needs,
# and only from local networks (home / office LAN), so nothing is open on
# public Wi-Fi. Outgoing traffic is not limited. Run in a terminal (sudo):
#   ~/.config/hypr/scripts/SetupFirewall.sh
# Check later with: sudo ufw status verbose
#
# Note: Docker publishes container ports through its own iptables rules, which
# skip ufw. Bind them to localhost (-p 127.0.0.1:8080:80) to keep them private.
set -euo pipefail

lans=(192.168.0.0/16 10.0.0.0/8 172.16.0.0/12)

# one firewall only
sudo systemctl disable --now firewalld 2>/dev/null || true

sudo ufw --force reset >/dev/null
sudo ufw default deny incoming
sudo ufw default allow outgoing

for lan in "${lans[@]}"; do
  # KDE Connect: phone pairing, notifications, file sharing
  sudo ufw allow proto tcp from "$lan" to any port 1714:1764 comment 'KDE Connect'
  sudo ufw allow proto udp from "$lan" to any port 1714:1764 comment 'KDE Connect'
  # LocalSend: send files to and from other devices
  sudo ufw allow proto tcp from "$lan" to any port 53317 comment 'LocalSend'
  sudo ufw allow proto udp from "$lan" to any port 53317 comment 'LocalSend'
  # Spotify Connect: control playback from the phone / see local speakers
  sudo ufw allow proto tcp from "$lan" to any port 57621 comment 'Spotify Connect'
  sudo ufw allow proto udp from "$lan" to any port 57621 comment 'Spotify Connect'
  # mDNS: finding devices on the network (KDE Connect, Spotify, printers)
  sudo ufw allow proto udp from "$lan" to any port 5353 comment 'mDNS'
done

sudo ufw --force enable
sudo systemctl enable ufw
sudo ufw status verbose
