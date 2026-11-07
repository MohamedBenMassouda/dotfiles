#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager. This script uses cliphist, rofi, and wl-copy.

# Variables
rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
msg='ALT P = view image   CTRL DEL = delete entry   ALT DEL = wipe all'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

# Check if rofi is already running
source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
menu_toggle ClipManager || exit 0

# Image previews: each image entry is decoded once into this cache as a square
# thumbnail and shown as the row's icon; text entries get a text icon so the
# list stays aligned. Alt+P opens the selected image full-size.
thumbs="$HOME/.cache/cliphist-thumbs"

clip_rows() {
  local list line id
  list=$(cliphist list)
  mkdir -p "$thumbs"
  # decode images that have no preview yet (fast; only new copies after the first run)
  grep -P '^\d+\t\[\[ binary data .* (png|jpe?g|webp|bmp|gif) ' <<<"$list" | cut -f1 |
    while read -r id; do [[ -s "$thumbs/$id.png" ]] || echo "$id"; done |
    xargs -r -P 8 -I{} sh -c 'cliphist decode "$1" | magick - -thumbnail 160x160^ -gravity center -extent 160x160 "$2/$1.png"' _ {} "$thumbs"
  # forget previews of entries that were deleted from the history
  comm -23 <(ls "$thumbs" | sed -n 's/\.png$//p' | sort) <(cut -f1 <<<"$list" | sort) |
    xargs -r -I{} rm -f "$thumbs/{}.png"
  while IFS= read -r line; do
    id=${line%%$'\t'*}
    if [[ "$line" == *"[[ binary data"* && -s "$thumbs/$id.png" ]]; then
      printf '%s\0icon\x1f%s\n' "$line" "$thumbs/$id.png"
    else
      printf '%s\0icon\x1f%s\n' "$line" "edit-paste"
    fi
  done <<<"$list"
}

while true; do
    result=$(
        rofi -i -dmenu -p Clipboard \
            -kb-custom-1 "Control-Delete" \
            -kb-custom-2 "Alt-Delete" \
            -kb-custom-3 "Alt+p" \
            -show-icons -config $rofi_theme < <(clip_rows) \
			-mesg "$msg" 
    )

    case "$?" in
        1)
            exit
            ;;
        0)
            case "$result" in
                "")
                    continue
                    ;;
                *)
                    cliphist decode <<<"$result" | wl-copy
                    exit
                    ;;
            esac
            ;;
        10)
            cliphist delete <<<"$result"
            ;;
        11)
            cliphist wipe
            ;;
        12)
            # Alt+P: open an image entry full-size in the default image viewer
            if [[ "$result" == *"[[ binary data"* ]]; then
                preview="${XDG_RUNTIME_DIR:-/tmp}/clipboard-preview.png"
                cliphist decode <<<"$result" >"$preview"
                setsid -f xdg-open "$preview" >/dev/null 2>&1
                exit
            fi
            ;;
        *)
            exit  # rofi was closed from outside (e.g. the key pressed again)
            ;;
    esac
done

