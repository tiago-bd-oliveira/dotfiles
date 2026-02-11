#!/bin/bash

# Check if hyprsunset daemon is running
if pgrep -f "^hyprsunset$" > /dev/null 2>&1; then
    # Process is running - filter is ON
    # Try to get the temperature - get first word from output
    TEMP=$(hyprctl hyprsunset temperature 2>/dev/null | awk '{print $1}')
    
    if [ -n "$TEMP" ]; then
        echo "{\"text\": \"󰅶\", \"tooltip\": \"Blue light filter: ${TEMP}K\", \"class\": \"on\"}"
    fi
else
    # Process not running - filter is OFF
    echo "{\"text\": \"󰅴\", \"tooltip\": \"Blue light filter: Off\", \"class\": \"off\"}"
fi
