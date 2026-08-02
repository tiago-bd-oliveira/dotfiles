#!/usr/bin/env bash
# Applies a pywal color scheme from a wallpaper and refreshes every integrated app.
# Usage: apply-wal.sh /path/to/wallpaper.jpg

set -euo pipefail

WALLPAPER="${1:-}"
ENGINE="$HOME/.config/hypr/scripts/wal-engine.py"

if [[ -z "$WALLPAPER" ]]; then
    echo "Usage: $0 /path/to/wallpaper.jpg" >&2
    exit 1
fi

# 1. Generate the base palette (colors.json, escape sequences, etc.)
wal -i "$WALLPAPER" -n -q
# -n: skip setting the wallpaper itself (hyprpaper already owns that job)
# -q: quiet

# 2. Run the consolidated engine: computes contrast-corrected fg + tonal
#    gradient once, then writes colors-kitty.conf, colors-waybar.css,
#    colors-rofi.rasi, colors-swaync.css from that single palette.
python3 "$ENGINE" "$WALLPAPER"

# 3. Reload each app

# Kitty: SIGUSR1 reloads its config (re-reads the included colors-kitty.conf),
# works without remote control enabled.
pkill -SIGUSR1 kitty 2>/dev/null || true

# Waybar: restart to pick up colors-waybar.css
pkill -SIGUSR2 waybar 2>/dev/null || {
    pkill waybar 2>/dev/null || true
    sleep 0.2
    waybar &
    disown
}

# Rofi: no reload needed, it reads its theme fresh on every launch

# SwayNC: reload its CSS live
if command -v swaync-client >/dev/null 2>&1; then
    swaync-client -rs 2>/dev/null || true
fi

echo "Applied pywal scheme from: $WALLPAPER"
