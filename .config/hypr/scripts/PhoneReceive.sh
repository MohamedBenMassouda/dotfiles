#!/usr/bin/env bash
# Files shared from a phone with KDE Connect (share sheet > KDE Connect): a picture goes
# straight into the clipboard, ready to paste (iPhone HEIC photos converted to PNG, since
# Linux apps can't paste HEIC); anything else just gets a flyout with where it was saved.
# KDE Connect saves them in ~/Downloads. Send the other way: PhoneSend.sh (SUPER+ALT+V).
# Started at login (configs/Startup_Apps.lua); one copy only (the lock file).
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/phone-receive.lock"
flock -n 9 || exit 0

toast() {  # toast TITLE SUBTITLE [IMAGE]
  local extra='{}'
  [[ -n ${3:-} ]] && extra=$(jq -nc --arg i "$3" '{image: $i}')
  qs ipc call osd rich phone "$1" "$2" "$extra" >/dev/null 2>&1 || notify-send "$1" "$2"
}

# the share plugin's D-Bus signal carries the saved file's URL, on the line after the header
dbus-monitor --session "type='signal',interface='org.kde.kdeconnect.device.share',member='shareReceived'" |
while read -r line; do
  [[ $line == string\ \"file://* ]] || continue
  url=${line#string \"}
  url=${url%\"}
  file=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(urllib.parse.urlparse(sys.argv[1]).path))' "$url")
  [[ -f $file ]] || continue
  mime=$(file --mime-type -b "$file")
  case $mime in
    image/png|image/jpeg|image/gif|image/webp)
      wl-copy --type "$mime" < "$file"
      toast "Picture from your phone copied" "Paste it anywhere · saved as ${file##*/}" "$file" ;;
    image/*)   # HEIC/HEIF and others: convert so it pastes everywhere
      png="${file%.*}.png"
      if magick "$file" "$png" 2>/dev/null; then
        wl-copy --type image/png < "$png"
        toast "Picture from your phone copied" "Paste it anywhere · saved as ${png##*/}" "$png"
      else
        toast "Picture from your phone saved" "${file##*/} (couldn't copy this format)"
      fi ;;
    *)
      toast "File from your phone" "Saved as ${file##*/} in ${file%/*}" ;;
  esac
done
