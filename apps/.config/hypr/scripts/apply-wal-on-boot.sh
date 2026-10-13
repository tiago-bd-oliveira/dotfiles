#!/usr/bin/env bash
# Picks a random startup wallpaper and applies the matching pywal theme, run
# once at Hyprland startup. Delegates to rotate-wallpaper.sh, which sets the
# wallpaper on every monitor, records it in the state file and runs apply-wal.sh.

set -euo pipefail

ROTATE="$HOME/.config/hypr/scripts/rotate-wallpaper.sh"

# Wait for hyprpaper to start, then give it (and waybar/kitty) a moment to be
# ready for IPC before rotate-wallpaper.sh / apply-wal.sh talk to them
for _ in {1..20}; do
    pgrep -x hyprpaper >/dev/null && break
    sleep 0.5
done
sleep 2

"$ROTATE"
