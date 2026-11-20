#!/usr/bin/env bash
# SUPER+ALT+V: send the clipboard to the phone with KDE Connect. Text lands in the phone's
# clipboard; a picture (a screenshot, an image copied from the browser…) is sent as a file
# (on iPhone: Files > KDE Connect, or straight into the share it asks about).
# The phone must have the KDE Connect app open: iOS pauses it in the background.
# The other way (phone > PC clipboard): PhoneReceive.sh.
toast() { qs ipc call osd toast phone "$1" "$2" >/dev/null 2>&1 || notify-send "$1" "$2"; }

id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -1)
if [[ -z $id ]]; then
  toast "No phone connected" "Open the KDE Connect app on your phone, then try again"
  exit 1
fi
name=$(kdeconnect-cli -a --name-only 2>/dev/null | head -1)

types=$(wl-paste --list-types 2>/dev/null)
if [[ -z $types ]]; then
  toast "Clipboard is empty" "Copy something first"
  exit 1
fi

image=$(grep -m1 -E '^image/(png|jpeg|gif|webp)' <<< "$types")
if [[ -n $image ]]; then
  dir="${XDG_CACHE_HOME:-$HOME/.cache}/phone-send"
  mkdir -p "$dir"
  find "$dir" -type f -mtime +1 -delete   # yesterday's sends are long delivered
  file="$dir/clipboard-$(date +%Y%m%d-%H%M%S).${image#image/}"
  wl-paste --type "$image" > "$file"
  kdeconnect-cli -d "$id" --share "$file" >/dev/null 2>&1 \
    && toast "Picture sent to $name" "Find it in the KDE Connect app" \
    || toast "Couldn't send to $name" "Is the KDE Connect app open on it?"
else
  # the clipboard plugin sends what's in the clipboard right now
  qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/clipboard" \
    org.kde.kdeconnect.device.clipboard.sendClipboard >/dev/null 2>&1 \
    && toast "Clipboard sent to $name" "Paste it on your phone" \
    || toast "Couldn't send to $name" "Is the KDE Connect app open on it?"
fi
