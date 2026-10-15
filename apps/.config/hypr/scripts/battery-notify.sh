#!/bin/bash

# Notify when the battery is low and discharging. Run by battery-notify.timer.
THRESHOLD=${BATTERY_THRESHOLD:-10}
CRITICAL=${BATTERY_CRITICAL:-5}
STATE="${XDG_RUNTIME_DIR:-/tmp}/battery-notify.stage"

for bat in /sys/class/power_supply/BAT*; do
    [ -r "$bat/capacity" ] || continue
    capacity=$(<"$bat/capacity")
    status=$(<"$bat/status")

    # Charging or above the threshold: re-arm for the next discharge
    if [ "$status" != "Discharging" ] || [ "$capacity" -gt "$THRESHOLD" ]; then
        rm -f "$STATE"
        exit 0
    fi

    # Stage 1 = warned at THRESHOLD, stage 2 = warned at CRITICAL
    stage=$(cat "$STATE" 2>/dev/null || echo 0)
    if [ "$capacity" -le "$CRITICAL" ]; then want=2; else want=1; fi

    if [ "$stage" -lt "$want" ]; then
        notify-send -u critical -i battery-caution -a "Battery" \
            "Battery low" "${capacity}% remaining — plug in the charger"
        echo "$want" > "$STATE"
    fi
    exit 0
done
