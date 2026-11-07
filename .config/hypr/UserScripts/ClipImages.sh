#!/usr/bin/env bash
# Clipboard image gallery (SUPER+SHIFT+V): only the images from the clipboard
# history, as a grid of big previews, newest first. SUPER+V is the full list.
#   Enter     copy the image back to the clipboard
#   Alt+P     open it full-size in the image viewer
#   Ctrl+Del  delete it from the history
source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
menu_toggle ClipImages || exit 0

# whole-image previews (no cropping), separate from SUPER+V's small square ones
cache="$HOME/.cache/cliphist-thumbs/grid"
mkdir -p "$cache"

while true; do
  mapfile -t lines < <(cliphist list | grep -P '^\d+\t\[\[ binary data .* (png|jpe?g|webp|bmp|gif) ')
  if [[ ${#lines[@]} -eq 0 ]]; then
    notify-send -e -u low " Clipboard" "No images in the clipboard history"
    exit 0
  fi

  # make previews for new images, forget previews of deleted ones
  printf '%s\n' "${lines[@]}" | cut -f1 |
    while read -r id; do [[ -s "$cache/$id.png" ]] || echo "$id"; done |
    xargs -r -P 8 -I{} sh -c 'cliphist decode "$1" | magick - -thumbnail 360x360 "$2/$1.png"' _ {} "$cache"
  comm -23 <(ls "$cache" | sed -n 's/\.png$//p' | sort) <(printf '%s\n' "${lines[@]}" | cut -f1 | sort) |
    xargs -r -I{} rm -f "$cache/{}.png"

  # tile label: "648x344 · 147 KiB png"
  mapfile -t labels < <(printf '%s\n' "${lines[@]}" |
    sed -E 's/.*binary data ([0-9.]+ [KMG]?i?B) ([a-z]+) ([0-9]+x[0-9]+).*/\3 · \1 \2/')
  choice=$(for i in "${!lines[@]}"; do
      printf '%s\0icon\x1f%s\n' "${labels[$i]}" "$cache/${lines[$i]%%$'\t'*}.png"
    done | rofi -dmenu -i -p Images -show-icons -format i \
      -kb-custom-1 "Control-Delete" -kb-custom-3 "Alt+p" \
      -config "$HOME/.config/rofi/config-clipboard-images.rasi" \
      -mesg "Enter copy   ALT P view full-size   CTRL DEL delete")
  rc=$?
  [[ -n "$choice" ]] || exit 0
  line=${lines[$choice]}

  case $rc in
    0)  cliphist decode <<<"$line" | wl-copy
        notify-send -e -u low " Clipboard" "Image copied"
        exit ;;
    10) cliphist delete <<<"$line" ;;  # back to the gallery
    12) preview="${XDG_RUNTIME_DIR:-/tmp}/clipboard-preview.png"
        cliphist decode <<<"$line" >"$preview"
        setsid -f xdg-open "$preview" >/dev/null 2>&1
        exit ;;
    *)  exit ;;
  esac
done
