#!/bin/bash

# Kill the current hyprsunset process to toggle
HYPRSUNSET_PID=$(pgrep -f "^hyprsunset$" | head -1)

if [ -z "$HYPRSUNSET_PID" ]; then
    # Daemon not running - start it
    nohup hyprsunset > /dev/null 2>&1 &
else
    # Daemon is running - kill it
    kill "$HYPRSUNSET_PID"
    
    # Schedule restart after 1 hour
    (sleep 3600 && nohup hyprsunset > /dev/null 2>&1 &) &
fi

