#!/bin/bash

while true; do
  # Get battery Level
  battery_level=$(cat /sys/class/power_supply/BAT1/capacity)

  # Get battery status
  battery_status=$(cat /sys/class/power_supply/BAT1/status)

  if [ "$battery_status" == "Discharging" ]; then
    if [ "$battery_level" -le 20 ]; then
      # Send notification
      notify-send -u critical "Battery Low" "Battery is at $battery_level%. Please plug in your charger."
    fi
  fi

  sleep 300
done

