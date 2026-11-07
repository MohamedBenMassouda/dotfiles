#!/usr/bin/env bash
# USB drives and SD cards, for the flyout (Quickshell's Osd.qml runs "Usb.sh watch")
#   Usb.sh watch        prints "add<TAB>/dev/sdb1<TAB>label<TAB>size" when a removable
#                       drive's filesystem appears, "remove<TAB>/dev/sdb1" when it goes
#   Usb.sh open DEV     mounts it if needed and opens it in the file manager
#   Usb.sh eject DEV    unmounts it and powers the drive off

toast() { qs ipc call osd toast "$@" >/dev/null 2>&1 || notify-send "$2" "$3"; }

# the whole disk a partition is on (/dev/sdb1 -> /dev/sdb)
disk_of() {
  local pk
  pk=$(lsblk -dno PKNAME "$1" 2>/dev/null)
  echo "/dev/${pk:-${1#/dev/}}"
}

removable() {
  [[ $(lsblk -dno HOTPLUG "$(disk_of "$1")" 2>/dev/null | tr -d ' ') == 1 ]]
}

case ${1:-} in
  watch)
    gdbus monitor --system --dest org.freedesktop.UDisks2 --object-path /org/freedesktop/UDisks2 |
      while read -r line; do
        [[ $line == *block_devices/* && $line == *org.freedesktop.UDisks2.Filesystem* ]] || continue
        dev=/dev/$(sed -n "s|.*block_devices/\([^']*\)'.*|\1|p" <<<"$line")
        case $line in
          *InterfacesAdded*)
            sleep 0.5   # let udev fill in the label
            removable "$dev" || continue
            printf 'add\t%s\t%s\t%s\n' "$dev" "$(lsblk -dno LABEL "$dev")" "$(lsblk -dno SIZE "$dev" | tr -d ' ')"
            ;;
          *InterfacesRemoved*)
            printf 'remove\t%s\n' "$dev"
            ;;
        esac
      done
    ;;
  open)
    dev=$2
    mp=$(lsblk -no MOUNTPOINT "$dev" | head -1)
    if [[ -z $mp ]]; then
      if ! err=$(udisksctl mount -b "$dev" 2>&1); then
        toast usb-off "Couldn't open the drive" "${err##*: }"
        exit 1
      fi
      mp=$(lsblk -no MOUNTPOINT "$dev" | head -1)
    fi
    xdg-open "$mp"
    ;;
  eject)
    dev=$2
    if [[ -n $(lsblk -no MOUNTPOINT "$dev" | head -1) ]] && ! err=$(udisksctl unmount -b "$dev" 2>&1); then
      toast usb "Can't eject yet" "Still in use: close the files on it first"
      exit 1
    fi
    # the drive disappearing makes the flyout say "safe to unplug" (watch: remove)
    udisksctl power-off -b "$(disk_of "$dev")" >/dev/null 2>&1 || toast usb "Unmounted" "Safe to unplug"
    ;;
  *)
    echo "usage: $0 watch | open DEV | eject DEV" >&2
    exit 1
    ;;
esac
