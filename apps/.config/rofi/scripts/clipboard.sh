#!/usr/bin/env bash

# Get the selection from rofi
# awk '{$1=$1; print $0}' strips ALL leading/trailing whitespace and collapses the tab gap
result=$(cliphist list | awk '{$1=$1; print $0}' | rofi -dmenu  -sort false -p "Clipboard")

# Exit if nothing was selected (Escape pressed)
[ -z "$result" ] && exit

# Handle the custom keybind (Alt+1 or the Delete key depends on rofi config)
# If you pressed your custom delete key:
if [ "$?" -eq 10 ]; then
    echo "$result" | cliphist decode | cliphist delete
    exec "$0" # Restart the script so the menu stays open
else
    # Otherwise, copy the selection
    echo "$result" | cliphist decode | wl-copy
fi
