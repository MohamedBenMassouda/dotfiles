#!/usr/bin/env bash
# Reads each disk's own health data (SMART) and writes one line per disk to
# /var/lib/disk-health/status: "<disk> OK <details>" or "<disk> PROBLEM <what>".
# Runs weekly as root (disk-health.timer); hypr/scripts/DiskHealth.sh shows a flyout at
# login when a line says PROBLEM. Installed by system/finish-setup.sh.
set -uo pipefail
out=/var/lib/disk-health
mkdir -p "$out"
tmp=$(mktemp)
echo "checked $(date -Iseconds)" > "$tmp"
for dev in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 !~ /^(zram|loop)/ {print $1}'); do
  json=$(smartctl -j -a "/dev/$dev" 2>/dev/null) || true
  [[ -n $json ]] || continue
  echo "$json" | jq -r --arg dev "$dev" '
    def n(x): (x // 0);
    (.model_name // "disk") as $model
    | [ (if .smart_status.passed == false then "the drive reports it is failing" else empty end),
        (if n(.nvme_smart_health_information_log.critical_warning) > 0 then "critical warning flag set" else empty end),
        (if n(.nvme_smart_health_information_log.percentage_used) >= 90 then "\(.nvme_smart_health_information_log.percentage_used)% of its rated life used" else empty end),
        (if n(.nvme_smart_health_information_log.media_errors) > 0 then "\(.nvme_smart_health_information_log.media_errors) unreadable blocks" else empty end),
        (.ata_smart_attributes.table // [] | map(select(.name == "Reallocated_Sector_Ct" and .raw.value > 0))
          | if length > 0 then "\(.[0].raw.value) worn-out sectors replaced" else empty end)
      ] as $problems
    | if ($problems | length) > 0 then "\($dev) PROBLEM \($model): \($problems | join(", "))"
      else "\($dev) OK \($model)" + (if .nvme_smart_health_information_log then ", \(.nvme_smart_health_information_log.percentage_used)% of life used" else "" end)
      end' >> "$tmp"
done
mv "$tmp" "$out/status"
chmod 644 "$out/status"
