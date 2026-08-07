#!/usr/bin/env bash
# Applies the pywal theme to match whatever wallpaper hyprpaper.conf declares,
# run once at Hyprland startup. Also seeds rotate-wallpaper.sh's state file so
# the first rotation won't immediately repeat this wallpaper.

set -euo pipefail

HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"
APPLY_WAL="$HOME/.config/hypr/scripts/apply-wal.sh"

WALLPAPER=$(grep -m1 -E '^\s*path\s*=' "$HYPRPAPER_CONF" | sed -E 's/^\s*path\s*=\s*//')

if [[ -z "$WALLPAPER" ]]; then
    echo "Could not find a wallpaper path in $HYPRPAPER_CONF" >&2
    exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"
echo "$WALLPAPER" > "$STATE_FILE"

# Give hyprpaper/waybar/kitty a moment to actually start before apply-wal.sh
# tries to reload them
sleep 2

"$APPLY_WAL" "$WALLPAPER"
