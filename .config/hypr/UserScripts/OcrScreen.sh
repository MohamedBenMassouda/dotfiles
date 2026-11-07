#!/usr/bin/env bash
# Copy text from the screen (SUPER+SHIFT+T): select an area, read it with
# tesseract, put the text in the clipboard. Other languages: OCR_LANG=eng+fra
toast() { qs ipc call osd toast ocr "$1" "$2" >/dev/null 2>&1 || notify-send -u low "$1" "$2"; }

command -v tesseract >/dev/null || { toast "Copy text" "Install tesseract first (scripts/SetupSystem.sh)"; exit 1; }
area=$(slurp) || exit 0
text=$(grim -g "$area" - | tesseract - - -l "${OCR_LANG:-eng}" 2>/dev/null | tr -d '\f')

if [[ -z ${text//[[:space:]]/} ]]; then
  toast "Copy text" "No text found"
else
  wl-copy <<<"$text"
  toast "Text copied" "$(tr '\n' ' ' <<<"$text" | cut -c1-60)"
fi
