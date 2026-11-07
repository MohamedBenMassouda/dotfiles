#!/usr/bin/env bash
# Quick notes in ~/Documents/notes, written in $EDITOR (nvim) in a floating kitty.
#   Notes.sh new      SUPER+ALT+N  new note, named by date (2026-11-07_1432.md)
#   Notes.sh search   SUPER+SHIFT+N  rofi list of notes, newest first; typing
#                     matches titles AND contents; Enter opens it
# After the editor closes: an empty note is deleted, and a new note whose first
# line is "# Some title" is renamed to some-title.md.
set -euo pipefail

dir="$HOME/Documents/notes"
mkdir -p "$dir"

edit() {
  cd "$dir"
  kitty --class notes --title "Note: ${1##*/}" -e "${EDITOR:-nvim}" "$@"
  tidy "$1"
}

tidy() {
  local f=$1 title slug new n=2
  [[ -f $f ]] || return 0
  if ! grep -q '[^[:space:]]' "$f"; then rm -f "$f"; return; fi
  # only rename notes still called by their date
  [[ ${f##*/} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}(-[0-9]+)?\.md$ ]] || return 0
  title=$(sed -n '1s/^#[[:space:]]\+//p' "$f")
  slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^[:alnum:]]\+/-/g; s/^-//; s/-$//')
  [[ -n $slug ]] || return 0
  new="$dir/$slug.md"
  while [[ -e $new ]]; do new="$dir/$slug-$n.md"; n=$((n + 1)); done
  mv "$f" "$new"
}

new_note() {
  local f n=2
  f="$dir/$(date +%F_%H%M).md"
  while [[ -e $f ]]; do f="$dir/$(date +%F_%H%M)-$n.md"; n=$((n + 1)); done
  edit "$f" +startinsert
}

search() {
  source "$HOME/.config/hypr/UserScripts/menu-toggle.sh"
  menu_toggle notes || exit 0
  local files=() choice f title body
  mapfile -t files < <(find "$dir" -type f -name '*.md' -printf '%T@ %p\n' | sort -rn | cut -d' ' -f2-)
  choice=$(
    {
      printf '%s\0icon\x1f%s\n' "New note" list-add
      for f in "${files[@]}"; do
        title=$(sed -n '1s/^#[[:space:]]\+//p' "$f")
        body=$(head -c 4000 "$f" | tr '\n\t\037' '   ')
        # hidden "meta" text: rofi matches it too, so typing finds words inside notes
        printf '%s   ·  %s\0icon\x1f%s\x1fmeta\x1f%s\n' "${title:-$(basename "$f" .md)}" \
          "$(date -r "$f" '+%d %b %H:%M')" text-x-generic "${f##*/} $body"
      done
    } | rofi -dmenu -i -p "Notes" -show-icons -format i -mesg "Type to search titles and contents"
  ) || exit 0
  [[ -n $choice ]] || exit 0
  if (( choice == 0 )); then new_note; else edit "${files[choice - 1]}"; fi
}

case ${1:-new} in
  new) new_note ;;
  search) search ;;
  *) echo "usage: $0 [new|search]" >&2; exit 1 ;;
esac
