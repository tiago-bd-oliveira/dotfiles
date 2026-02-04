#!/usr/bin/env bash

config="$HOME/.config/rofi/custom-configs/clipboard.rasi"

# Get clipboard list, display only content (without ID), but keep ID mapping
# cliphist list format: <id>\t<content>
selected=$(cliphist list | rofi -dmenu -sort false -p "Clipboard" -config "${config}" -display-columns 2)
exit_code=$?

[ -z "$selected" ] && exit

if [ "$exit_code" -eq 10 ]; then
    echo "$selected" | cliphist delete
    exec "$0"
else
    echo "$selected" | cliphist decode | wl-copy
fi
