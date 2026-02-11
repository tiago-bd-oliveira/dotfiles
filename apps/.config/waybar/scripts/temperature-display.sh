#!/bin/bash

# Get the current hyprsunset state
TEMP=$(hyprctl hyprsunset temperature 2>/dev/null | awk '{print $NF}')

if [ -z "$TEMP" ] || [ "$TEMP" == "identity" ]; then
    echo "{\"text\": \"󰅶\", \"tooltip\": \"Blue light filter: Off\", \"class\": \"off\"}"
else
    # Extract just the numeric value
    TEMP_NUM=$(echo "$TEMP" | grep -oP '\d+' | head -1)
    if [ -n "$TEMP_NUM" ]; then
        echo "{\"text\": \"󰅶 ${TEMP_NUM}K\", \"tooltip\": \"Blue light filter: ${TEMP_NUM}K\", \"class\": \"on\"}"
    else
        echo "{\"text\": \"󰅶 $TEMP\", \"tooltip\": \"Blue light filter active\", \"class\": \"on\"}"
    fi
fi