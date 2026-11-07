#!/usr/bin/env bash
# Media applet (SUPER+P): album art + song info, then previous, play/pause,
# next, stop and go to Spotify. Uses MediaCtrl.sh so the usual notifications appear.
source "$(dirname "$(realpath "$0")")/applet.sh"
menu_toggle media || exit 0
ctl="$HOME/.config/hypr/scripts/MediaCtrl.sh"
cache="$HOME/.cache/media-art"

esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; printf '%s' "${s//>/&gt;}"; }

status=$(playerctl status 2>/dev/null || echo "Stopped")
IFS=$'\t' read -r title artist album art_url < <(
  playerctl metadata --format $'{{xesam:title}}\t{{xesam:artist}}\t{{xesam:album}}\t{{mpris:artUrl}}' 2>/dev/null || true)

case "$status" in
  Playing) play=$'\U000F03E4|Pause' ;;
  *)       play=$'\U000F040A|Play' ;;
esac

# Album art: local file as-is, web URL downloaded once into ~/.cache/media-art
art=""
case "${art_url:-}" in
  file://*) art=${art_url#file://} ;;
  http*)
    mkdir -p "$cache"
    art="$cache/$(printf '%s' "$art_url" | md5sum | cut -c1-16).jpg"
    [[ -s "$art" ]] || curl -sfL --max-time 3 -o "$art" "$art_url" || art=""
    ;;
esac

if [[ -n "${title:-}" ]]; then
  mesg="<b>$(esc "$title")</b>"$'\n'"$(esc "${artist:-Unknown artist}")"
  [[ -n "${album:-}" && "$album" != "$title" ]] && mesg+=" · $(esc "$album")"
  mesg+=$'\n'"<span size=\"small\">$status</span>"
else
  mesg="Nothing playing"
fi

# Put the cover to the left of the song info
if [[ -n "$art" && -s "$art" ]]; then
  # widget names must be quoted inside a custom box, or rofi leaves the buttons out
  APPLET_THEME="mainbox { children: [ \"header\", \"listview\" ]; }
    header { orientation: horizontal; expand: false; spacing: 12px; children: [ \"art\", \"message\" ]; }
    art { expand: false; padding: 48px; border-radius: 8px; background-image: url(\"$art\", both); }
    message { expand: true; }
    textbox { horizontal-align: 0; vertical-align: 0.5; }"
  export APPLET_THEME
fi

APPLET_ROW=1  # start on play/pause: SUPER+P then Enter toggles playback
choice=$(applet "$mesg" \
  $'\U000F04AE|Previous' \
  "$play" \
  $'\U000F04AD|Next' \
  $'\U000F04DB|Stop' \
  $'\U000F075A|Spotify') || exit 0

case "$choice" in
  0) "$ctl" --prv ;;
  1) "$ctl" --pause ;;
  2) "$ctl" --nxt ;;
  3) "$ctl" --stop ;;
  4) # jump to Spotify, or start it
     if hyprctl clients -j | jq -e 'any(.[]; .class | test("^[Ss]potify$"))' >/dev/null; then
       hyprctl dispatch 'hl.dsp.focus({ window = "class:^([Ss]potify)$" })' >/dev/null
     else
       setsid -f flatpak run com.spotify.Client >/dev/null 2>&1
     fi ;;
esac
