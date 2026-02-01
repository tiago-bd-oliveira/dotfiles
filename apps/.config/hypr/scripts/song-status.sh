#!/bin/bash
# Check if a player is running
if playerctl status >/dev/null 2>&1; then
    # Get status (Playing/Paused)
    STATUS=$(playerctl status)
    
    if [ "$STATUS" = "Playing" ]; then
        # Grab metadata
        ARTIST=$(playerctl metadata artist)
        TITLE=$(playerctl metadata title)
        # Output format: Song - Artist
        echo " $TITLE - $ARTIST"
    elif [ "$STATUS" = "Paused" ]; then
        echo " Paused"
    fi
else
    # Output nothing if no player is found
    echo ""
fi