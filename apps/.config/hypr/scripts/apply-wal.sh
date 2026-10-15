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

# Waybar: nothing to do when it's already running. "reload_style_on_change" in
# config.jsonc has it watching style.css and the files style.css imports, so the
# colors-waybar.css written above already swapped the CSS provider in place — no
# SIGUSR2, no bar teardown, no flicker. (SIGUSR2 would recreate every bar and
# layer surface, which is the visible restart we're avoiding.)
# Only start it if it isn't up yet, and only from inside a Wayland session —
# the systemd timer path has no display, and spawning there just logs
# "cannot open display".
if ! pgrep -x waybar >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    waybar &
    disown
fi

# Rofi: no reload needed, it reads its theme fresh on every launch

# Wleave: runs as a background service (hyprland.lua) and only reads its CSS at
# startup, so restart it. Spawn through Hyprland rather than directly — when
# run from the systemd timer, the oneshot unit would kill it on exit.
if pkill -x wleave 2>/dev/null && command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch 'hl.dsp.exec_cmd("wleave --service")' >/dev/null 2>&1 || true
fi

# SwayNC: reload its CSS live
if command -v swaync-client >/dev/null 2>&1; then
    swaync-client -rs 2>/dev/null || true
fi

echo "Applied pywal scheme from: $WALLPAPER"
