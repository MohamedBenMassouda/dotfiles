#!/usr/bin/env bash
# Log out / restart / shut down: hyprshutdown closes the apps gracefully,
# exits Hyprland, then reboots or powers off.
#   Power.sh logout | reboot | poweroff
# hyprshutdown runs in its own systemd unit: started from inside Hyprland's
# session it got killed together with Hyprland before it could run
# poweroff/reboot, leaving a black screen with a cursor.
case ${1:-} in
  logout)   label='Logging out...';   post= ;;
  reboot)   label='Restarting...';    post='systemctl reboot' ;;
  poweroff) label='Shutting down...'; post='systemctl poweroff' ;;
  *) echo "usage: $0 logout|reboot|poweroff" >&2; exit 1 ;;
esac
args=(--no-fork -t "$label")
[[ -n $post ]] && args+=(--post-cmd "$post")
systemd-run --user --quiet --collect --unit="hyprshutdown-$$" \
  -E WAYLAND_DISPLAY -E HYPRLAND_INSTANCE_SIGNATURE -E XDG_RUNTIME_DIR \
  hyprshutdown "${args[@]}" && exit 0
# no systemd user session: last resort, act directly
[[ -n $post ]] && exec $post
hyprctl dispatch 'hl.dsp.exit()'
