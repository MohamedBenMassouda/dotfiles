#!/usr/bin/env bash
# tmux status bar (~/.tmux.conf, every 5 s): RAM and NVIDIA video memory in use, red when
# nearly full, so a training run heading for the limit shows before systemd-oomd steps in.
read -r total avail < <(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
used=$(( total - avail ))
ram=$(awk -v u="$used" 'BEGIN {printf "%.1f", u / 1048576}')
(( used * 100 / total >= 85 )) && printf '#[fg=red]'
printf '󰍛 %sG#[default]' "$ram"
read -r vused vtotal < <(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ',')
if [[ -n ${vused:-} ]]; then
  printf '  '
  (( vused * 100 / vtotal >= 90 )) && printf '#[fg=red]'
  printf '󰢮 %sG#[default]' "$(awk -v m="$vused" 'BEGIN {printf "%.1f", m / 1024}')"
fi
