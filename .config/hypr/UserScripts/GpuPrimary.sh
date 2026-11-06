#!/usr/bin/env bash
# Switch which GPU Hyprland uses as its primary renderer.
#
# This CANNOT be automatic on AC/battery: Aquamarine reads AQ_DRM_DEVICES once,
# at backend init, so the primary GPU is fixed for the life of the compositor.
# Changing it always requires a fresh Hyprland session. Hence a manual toggle.
#
#   nvidia - renders on the card that drives HDMI-A-1 @179Hz. No PCIe copy for
#            the external display. dGPU stays powered (~14W idle and up).
#   intel  - renders on the iGPU. dGPU can idle down; the 179Hz external
#            display costs a cross-GPU copy every frame.
#
# IMPORTANT: AQ_DRM_DEVICES is a COLON-separated list, so /dev/dri/by-path/
# names cannot be used - they contain colons (pci-0000:01:00.0-card) and get
# shredded into fragments, leaving Hyprland with no GPU and a failed login.
# Only /dev/dri/cardN works. Card numbers are not guaranteed stable across
# boots, so we resolve them from the fixed PCI addresses on every write, and
# 'status' re-checks that the stored line still points where it should.
#
# Usage: GpuPrimary.sh [nvidia|intel|toggle|status]
# Bound to SUPER ALT G (UserKeybinds.lua) as 'toggle'.

set -euo pipefail

CONF="$HOME/.config/hypr/UserConfigs/ENVariables.lua"
NV_PCI="0000:01:00.0"   # NVIDIA GTX 1650 Ti -> drives HDMI-A-1
IN_PCI="0000:00:02.0"   # Intel UHD          -> drives eDP-1

# PCI address -> /dev/dri/cardN, resolved fresh each time.
card_for() {
  local d
  d=$(ls -d /sys/bus/pci/devices/"$1"/drm/card* 2>/dev/null | head -1) || true
  [[ -n "$d" ]] || { echo "ERROR: no DRM card for PCI $1" >&2; return 1; }
  echo "/dev/dri/$(basename "$d")"
}

notify() {
  command -v notify-send >/dev/null || return 0
  notify-send -a "GPU" -i "${2:-video-display}" \
    -h string:x-canonical-private-synchronous:gpu-primary "$1" "${3:-}"
}

# Which GPU does the stored line name first? Reads the live PCI mapping, so a
# card renumber shows up as a mismatch instead of silently pointing elsewhere.
current() {
  local line first
  line=$(grep -m1 '^hl.env("AQ_DRM_DEVICES"' "$CONF" 2>/dev/null) || { echo unset; return; }
  first=$(sed -E 's/.*"AQ_DRM_DEVICES", *"([^"]*)".*/\1/' <<<"$line")
  first=${first%%:*}
  first=${first%% *}
  if   [[ "$first" == "$(card_for "$NV_PCI")" ]]; then echo nvidia
  elif [[ "$first" == "$(card_for "$IN_PCI")" ]]; then echo intel
  else echo "stale:$first"
  fi
}

write_line() {
  local target="$1" first second value
  if [[ "$target" == nvidia ]]; then
    first=$(card_for "$NV_PCI"); second=$(card_for "$IN_PCI")
  else
    first=$(card_for "$IN_PCI"); second=$(card_for "$NV_PCI")
  fi
  value="$first:$second"

  # Guard: exactly one colon, both devices real. This is the check that would
  # have caught the by-path bug before it ever reached a login screen.
  [[ $(grep -o ':' <<<"$value" | wc -l) -eq 1 ]] \
    || { echo "ERROR: refusing to write malformed list '$value'" >&2; return 1; }
  [[ -e "$first" && -e "$second" ]] \
    || { echo "ERROR: device missing in '$value'" >&2; return 1; }

  # Drop any previous managed line, then append the new one.
  sed -i '\|^hl.env("AQ_DRM_DEVICES", "/dev/dri/card|d' "$CONF"
  printf 'hl.env("AQ_DRM_DEVICES", "%s")\n' "$value" >> "$CONF"
}

action="${1:-status}"
if [[ "$action" == toggle ]]; then
  case "$(current)" in
    nvidia) action=intel ;;
    *)      action=nvidia ;;   # intel, unset or stale -> nvidia
  esac
fi

case "$action" in
  status)
    echo "primary GPU at next login: $(current)"
    echo "  stored: $(grep -m1 '^hl.env("AQ_DRM_DEVICES"' "$CONF" 2>/dev/null || echo '(none - Aquamarine picks by enumeration order)')"
    echo "  live:   nvidia=$(card_for "$NV_PCI")  intel=$(card_for "$IN_PCI")"
    if pgrep -x Hyprland >/dev/null; then
      echo "  active this session: $(tr '\0' '\n' < "/proc/$(pgrep -x Hyprland)/environ" \
        | grep '^AQ_DRM_DEVICES=' | cut -d= -f2- || echo '(unset)')"
    fi
    ;;
  nvidia|intel)
    if [[ "$(current)" == "$action" ]]; then
      echo "already set to $action"
      notify "GPU already set to ${action^}" video-display "Log out to apply."
      exit 0
    fi
    if ! write_line "$action"; then
      notify "GPU switch FAILED" dialog-error "Config unchanged. See $CONF"
      exit 1
    fi
    [[ "$(current)" == "$action" ]] \
      || { echo "ERROR: verify failed, check $CONF" >&2
           notify "GPU switch FAILED" dialog-error "Verify failed. See $CONF"; exit 1; }
    echo "primary GPU set to $action - log out and back in to apply."
    if [[ "$action" == nvidia ]]; then
      notify "GPU primary: NVIDIA" video-display \
        "1650Ti drives HDMI-A-1 @179Hz directly. dGPU stays powered.
Log out and back in to apply."
    else
      notify "GPU primary: Intel" video-display \
        "iGPU renders; dGPU can idle down. Better on battery.
Log out and back in to apply."
    fi
    ;;
  *)
    echo "usage: ${0##*/} [nvidia|intel|toggle|status]" >&2
    exit 1
    ;;
esac
