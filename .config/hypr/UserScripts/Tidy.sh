#!/usr/bin/env bash
# Tidy.sh: puts files where they belong, and says what it did in a flyout.
#   Tidy.sh                      sort (moves only, deletes nothing)
#   Tidy.sh --trash-old DAYS     also move screenshots and KDE Connect files older than DAYS
#                                to the trash (recoverable from the file manager's Trash).
#                                Runs daily with 3 days: .config/systemd/user/tidy.timer
#   Tidy.sh --quiet              no flyout when there was nothing to do (the weekly timer)
#
# - Screenshots: screenshot-named files lying in ~, Downloads, Pictures or Desktop go to
#   ~/Pictures/Screenshots (where hypr/scripts/ScreenShot.sh saves new ones).
# - KDE Connect: every phone saves to ~/Pictures/kde-connect (set here for each paired
#   phone); anything that isn't a picture or video moves on to ~/Documents/kde-connect.
#   The old ~/Documents/Kdeconnect folder is sorted the same way.
# - Clipboard history (cliphist): with --trash-old, pictures copied more than DAYS ago are
#   removed from it (every screenshot is copied, so they piled up there too). cliphist keeps
#   no dates, so the day each picture first shows up is noted in ~/.local/state/tidy-clip-images;
#   the first time, everything but the newest 20 pictures goes. Text entries are left alone.
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

moved_shots=0 moved_phone=0 trashed=0 trashed_phone=0

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

if [[ -n $trash_days ]]; then
  while IFS= read -r -d '' f; do
    gio trash -- "$f" && trashed_phone=$((trashed_phone + 1))
  done < <(find "$phone_media" "$phone_files" -type f -mtime +"$trash_days" -print0)
fi

# ---- clipboard history pictures ----
removed_clip=0
if [[ -n $trash_days ]] && command -v cliphist >/dev/null; then
  seen="${XDG_STATE_HOME:-$HOME/.local/state}/tidy-clip-images"
  mkdir -p "${seen%/*}"
  first_time=false
  [[ -f $seen ]] || first_time=true
  touch "$seen"
  today=$(date +%s)
  # picture entries, newest first: "<id>\t[[ binary data … ]]"
  mapfile -t images < <(cliphist list | awk -F'\t' '$2 ~ /^\[\[ binary data/ {print $1}')
  declare -A first_seen=()
  while read -r id when; do [[ -n $id ]] && first_seen[$id]=$when; done < "$seen"
  kept=() index=0
  for id in "${images[@]}"; do
    index=$((index + 1))
    when=${first_seen[$id]:-}
    if $first_time && (( index > 20 )); then
      old=true
    elif [[ -z $when ]]; then
      when=$today old=false
    else
      (( today - when > trash_days * 86400 )) && old=true || old=false
    fi
    if $old; then
      printf '%s\t\n' "$id" | cliphist delete && removed_clip=$((removed_clip + 1))
    else
      kept+=("$id ${when:-$today}")
    fi
  done
  printf '%s\n' "${kept[@]}" > "$seen"
fi

# ---- leftovers ----
find "${XDG_CACHE_HOME:-$HOME/.cache}/phone-send" -type f -mtime +1 -delete 2>/dev/null

# ---- report ----
parts=()
(( moved_shots )) && parts+=("$moved_shots screenshots to Pictures/Screenshots")
(( moved_phone )) && parts+=("$moved_phone phone files sorted")
(( trashed )) && parts+=("$trashed old screenshots to the trash")
(( trashed_phone )) && parts+=("$trashed_phone old phone files to the trash")
(( removed_clip )) && parts+=("$removed_clip old pictures out of the clipboard history")
if (( ${#parts[@]} )); then
  summary=$(IFS=';'; echo "${parts[*]}" | sed 's/;/ · /g')
  echo "$summary"
  qs ipc call osd toast done "Tidied up" "$summary" >/dev/null 2>&1 || notify-send "Tidied up" "$summary"
elif ! $quiet; then
  echo "Nothing to tidy"
  qs ipc call osd toast done "Nothing to tidy" "Everything is already in its place" >/dev/null 2>&1
fi
