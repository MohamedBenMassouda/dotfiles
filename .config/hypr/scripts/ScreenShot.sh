#!/usr/bin/env bash
# Screenshots. Every shot is saved to ~/Pictures/Screenshots and copied, then
# the flyout shows a preview with Edit (swappy) / Open / Folder / Delete.
#   --now  --in5  --in10   the focused monitor (now, or after a countdown)
#   --area                 drag to pick an area
#   --win / --active       the focused window
#   --swappy               pick an area, copy it only (not saved), Edit offered

time=$(date "+%d-%b_%H-%M-%S")
dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
file="$dir/Screenshot_${time}_${RANDOM}.png"
sDIR="$HOME/.config/hypr/scripts"
mkdir -p "$dir"

# full-screen shots: only the monitor you're on
screen() { grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" -; }

toast() { qs ipc call osd toast "$@" >/dev/null 2>&1 || notify-send "$2" "$3"; }

# preview card for a finished shot (glyphs: image-edit, image, folder-open, delete)
preview() {
  local f=$1 title=${2:-Screenshot saved} extra
  if [[ ! -s $f ]]; then
    "$sDIR/Sounds.sh" --error
    toast screenshot-off "Screenshot not saved" ""
    return
  fi
  "$sDIR/Sounds.sh" --screenshot
  extra=$(jq -nc --arg f "$f" --arg d "${f%/*}" --arg clip "${3:-}" '{image: $f, actions: (
    [{label: "Edit", glyph: 987619, cmd: ["swappy", "-f", $f]}] +
    (if $clip == "" then [
      {label: "Open", glyph: 983785, cmd: ["xdg-open", $f]},
      {label: "Folder", glyph: 984944, cmd: ["xdg-open", $d]},
      {label: "Delete", glyph: 983476, cmd: ["rm", "-f", $f], then: ["screenshot-off", "Screenshot deleted", ""]}
    ] else [] end))}')
  qs ipc call osd rich screenshot "$title" "$([[ -n ${3:-} ]] && echo "Not saved" || echo "Copied to the clipboard too")" "$extra" >/dev/null 2>&1 ||
    notify-send -i "$f" "$title" "${f##*/}"
}

countdown() {
  for sec in $(seq "$1" -1 1); do
    toast screenshot "Screenshot in $sec" ""
    sleep 1
  done
  sleep 0.5   # let the flyout fade out of the picture
}

case $1 in
  --now)   screen | tee "$file" | wl-copy; preview "$file" ;;
  --in5)   countdown 5;  screen | tee "$file" | wl-copy; preview "$file" ;;
  --in10)  countdown 10; screen | tee "$file" | wl-copy; preview "$file" ;;
  --area)
    geo=$(slurp) || exit 0
    grim -g "$geo" - | tee "$file" | wl-copy
    preview "$file"
    ;;
  --win|--active)
    class=$(hyprctl -j activewindow | jq -r '.class')
    file="$dir/Screenshot_${time}_${class}.png"
    hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - - | tee "$file" | wl-copy
    preview "$file" "Screenshot of $class"
    ;;
  --swappy)
    geo=$(slurp) || exit 0
    tmp="${XDG_RUNTIME_DIR:-/tmp}/screenshot-clip.png"
    grim -g "$geo" - | tee "$tmp" | wl-copy
    preview "$tmp" "Copied to clipboard" clip
    ;;
  *) echo "Options: --now --in5 --in10 --area --win --active --swappy" ;;
esac
exit 0
