#!/usr/bin/env bash
# Bluetooth audio profiles (used by quick settings > Bluetooth).
#   BtProfile.sh list           JSON: connected Bluetooth audio devices with their profiles
#   BtProfile.sh set ID NAME    switch device ID to profile NAME (e.g. a2dp-sink)
#   BtProfile.sh best [ID]      back to the best-sounding profile (AAC > SBC-XQ > SBC)
# Switches with wpctl, which doesn't save the choice: the next connection
# starts on AAC again (wireplumber.conf.d/51-bluetooth-profiles.conf).
set -euo pipefail

devices() {
  pw-dump | jq '[.[] | select(.type == "PipeWire:Interface:Device" and .info.props["device.api"] == "bluez5")
    | { id, name: .info.props["device.description"],
        active: ((.info.params.Profile // [])[0].name // ""),
        profiles: [(.info.params.EnumProfile // [])[] | select(.available != "no" and .name != "off")
                   | { index, name, description, priority }] }]'
}

set_profile() {   # id name
  local idx
  idx=$(devices | jq -r --argjson id "$1" --arg n "$2" '.[] | select(.id == $id) | .profiles[] | select(.name == $n) | .index')
  [[ -n $idx ]] || { echo "no profile $2 on device $1" >&2; exit 1; }
  wpctl set-profile "$1" "$idx"
}

case ${1:-list} in
  list) devices ;;
  set) set_profile "$2" "$3" ;;
  best)
    for id in ${2:-$(devices | jq -r '.[].id')}; do
      for p in a2dp-sink a2dp-sink-sbc_xq a2dp-sink-sbc; do
        set_profile "$id" "$p" 2>/dev/null && break
      done
    done ;;
  *) sed -n '2,7p' "$0"; exit 2 ;;
esac
