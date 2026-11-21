#!/usr/bin/env bash
# Tidy.sh: puts files where they belong, and says what it did in a flyout.
#   Tidy.sh                      sort (moves only, deletes nothing)
#   Tidy.sh --trash-old DAYS     also move screenshots older than DAYS to the trash
#                                (recoverable from the file manager's Trash)
#   Tidy.sh --quiet              no flyout when there was nothing to do (the weekly timer)
#
# - Screenshots: screenshot-named files lying in ~, Downloads, Pictures or Desktop go to
#   ~/Pictures/Screenshots (where hypr/scripts/ScreenShot.sh saves new ones).
# - KDE Connect: every phone saves to ~/Pictures/kde-connect (set here for each paired
#   phone); anything that isn't a picture or video moves on to ~/Documents/kde-connect.
#   The old ~/Documents/Kdeconnect folder is sorted the same way.
# - Leftovers: clipboard pictures sent to the phone (~/.cache/phone-send) after a day.
# Files are never overwritten: a name that's taken gets " (2)", " (3)"… added.
set -uo pipefail

trash_days="" quiet=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --trash-old) trash_days=${2:?days}; shift 2 ;;
    --quiet) quiet=true; shift ;;
    *) sed -n '2,7p' "$0"; exit 2 ;;
  esac
done

user_dir() {  # user_dir NAME FALLBACK: xdg-user-dir answers $HOME itself when unset
  local d
  d=$(xdg-user-dir "$1" 2>/dev/null)
  [[ -n $d && $d != "$HOME" && $d != "$HOME/" ]] && echo "$d" || echo "$HOME/$2"
}
pictures=$(user_dir PICTURES Pictures)
documents=$(user_dir DOCUMENTS Documents)
downloads=$(user_dir DOWNLOAD Downloads)
desktop=$(user_dir DESKTOP Desktop)
shots="$pictures/Screenshots"
phone_media="$pictures/kde-connect"
phone_files="$documents/kde-connect"
mkdir -p "$shots" "$phone_media" "$phone_files"

moved_shots=0 moved_phone=0 trashed=0

move() {  # move FILE DIR, without overwriting
  local file=$1 dir=$2 name base ext target n=2
  name=${file##*/}
  target="$dir/$name"
  if [[ -e $target ]]; then
    base=${name%.*} ext=${name##*.}
    [[ $base == "$name" ]] && ext="" || ext=".$ext"
    while [[ -e "$dir/$base ($n)$ext" ]]; do n=$((n + 1)); done
    target="$dir/$base ($n)$ext"
  fi
  mv -n -- "$file" "$target"
}

is_media() { [[ $(file --mime-type -b "$1") == image/* || $(file --mime-type -b "$1") == video/* ]]; }

# ---- screenshots ----
while IFS= read -r -d '' f; do
  move "$f" "$shots" && moved_shots=$((moved_shots + 1))
done < <(find "$HOME" "$downloads" "$pictures" "$desktop" -maxdepth 1 -type f \
           \( -iname '*screenshot*' -o -iname '*hyprshot*' -o -iname 'grim_*' \) -print0 2>/dev/null)

if [[ -n $trash_days ]]; then
  while IFS= read -r -d '' f; do
    gio trash -- "$f" && trashed=$((trashed + 1))
  done < <(find "$shots" -type f -mtime +"$trash_days" -print0)
fi

# ---- KDE Connect ----
# every paired phone saves into the same folder (KDE Connect reads this per phone)
for dev in "$HOME"/.config/kdeconnect/*/; do
  id=$(basename "$dev")
  [[ $id == *_*_*_*_* ]] || continue   # device folders are ids like 2220cacc_0326_…
  kwriteconfig6 --file "kdeconnect/$id/kdeconnect_share/config" --group General \
    --key incoming_path "$phone_media" 2>/dev/null
done

for src in "$phone_media" "$documents/Kdeconnect"; do
  [[ -d $src ]] || continue
  while IFS= read -r -d '' f; do
    if is_media "$f"; then
      [[ $src == "$phone_media" ]] && continue
      move "$f" "$phone_media" && moved_phone=$((moved_phone + 1))
    else
      move "$f" "$phone_files" && moved_phone=$((moved_phone + 1))
    fi
  done < <(find "$src" -maxdepth 1 -type f -print0)
done
rmdir "$documents/Kdeconnect" 2>/dev/null   # only if it ended up empty

# ---- leftovers ----
find "${XDG_CACHE_HOME:-$HOME/.cache}/phone-send" -type f -mtime +1 -delete 2>/dev/null

# ---- report ----
parts=()
(( moved_shots )) && parts+=("$moved_shots screenshots to Pictures/Screenshots")
(( moved_phone )) && parts+=("$moved_phone phone files sorted")
(( trashed )) && parts+=("$trashed old screenshots to the trash")
if (( ${#parts[@]} )); then
  summary=$(IFS=';'; echo "${parts[*]}" | sed 's/;/ · /g')
  echo "$summary"
  qs ipc call osd toast done "Tidied up" "$summary" >/dev/null 2>&1 || notify-send "Tidied up" "$summary"
elif ! $quiet; then
  echo "Nothing to tidy"
  qs ipc call osd toast done "Nothing to tidy" "Everything is already in its place" >/dev/null 2>&1
fi
