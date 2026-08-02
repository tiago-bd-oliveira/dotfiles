#!/usr/bin/env bash
# Rotates to a random wallpaper (different from the current one) across all
# connected monitors via hyprpaper's IPC, then regenerates the pywal theme.
#
# Requires: jq, hyprpaper running, apply-wal.sh already in place.

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"
APPLY_WAL="$HOME/.config/hypr/scripts/apply-wal.sh"

mkdir -p "$(dirname "$STATE_FILE")"

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) | sort)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "No wallpapers found in $WALLPAPER_DIR" >&2
    exit 1
fi

CURRENT=""
[[ -f "$STATE_FILE" ]] && CURRENT=$(cat "$STATE_FILE")

NEXT="$CURRENT"
if [[ ${#WALLPAPERS[@]} -gt 1 ]]; then
    # Pick randomly, but avoid repeating the current one back-to-back
    while [[ "$NEXT" == "$CURRENT" ]]; do
        NEXT="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"
    done
else
    NEXT="${WALLPAPERS[0]}"
fi

# Apply the new wallpaper to every connected monitor.
# Note: hyprpaper dropped the separate "preload" request in recent versions —
# "wallpaper" now applies the image directly, no preload step needed or supported.
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
for MON in "${MONITORS[@]}"; do
    hyprctl hyprpaper wallpaper "$MON,$NEXT"
done

# Unload the previous wallpaper to free memory, if it changed
if [[ -n "$CURRENT" && "$CURRENT" != "$NEXT" ]]; then
    hyprctl hyprpaper unload "$CURRENT" 2>/dev/null || true
fi

echo "$NEXT" > "$STATE_FILE"

# Regenerate pywal theme (waybar + kitty) to match the new wallpaper
if [[ -x "$APPLY_WAL" ]]; then
    "$APPLY_WAL" "$NEXT"
fi

echo "Rotated wallpaper to: $NEXT"
