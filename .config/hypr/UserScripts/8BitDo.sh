#!/usr/bin/env bash
# 8BitDo Ultimate Software V2 (Windows app) under Proton, for controller
# profiles / button mapping. App in ~/Applications/8BitDo (official zip from
# app.8bitdo.com), its own prefix there. PROTON_ENABLE_HIDRAW lets it talk to
# the controller (Proton hides raw USB devices otherwise).
# Firmware updates: use Windows or the phone app, not this.
D="$HOME/Applications/8BitDo"
exe=$(find "$D" -maxdepth 2 -name '8BitDo Ultimate Software V2.exe' | sort | tail -1)
[[ -n $exe ]] || { notify-send "8BitDo" "App not found in $D"; exit 1; }
cd "${exe%/*}" && WINEPREFIX="$D/proton-prefix" GAMEID=umu-default PROTON_ENABLE_HIDRAW=1 exec umu-run "$exe"
