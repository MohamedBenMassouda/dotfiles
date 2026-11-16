#!/usr/bin/env bash
# Connected game controllers, for the bar and flyouts (Quickshell):
#   Controllers.sh          print them once as a JSON array of names
#   Controllers.sh watch    print the list again each time input devices change
# A controller = an input device with a joystick handler (jsN), e.g.
# "8BitDo Ultimate 2 Wireless Controller". Battery levels come from UPower.
list() {
  awk '/^N: Name=/{sub(/^N: Name="/, ""); sub(/"$/, ""); n=$0} /^H: Handlers=/ && / js[0-9]/{print n}' /proc/bus/input/devices |
    grep -viE 'accelerometer|motion sensors|touchpad' | sort -u | jq -Rcs 'split("\n") | map(select(length > 0))'
}
case ${1:-} in
  watch)
    list
    last=$(list)
    udevadm monitor --udev --subsystem-match=input 2>/dev/null | while read -r line; do
      [[ $line == UDEV* ]] || continue
      sleep 0.5   # let the device settle (several events per controller)
      now=$(list)
      [[ $now != "$last" ]] && { echo "$now"; last=$now; }
    done
    ;;
  *) list ;;
esac
