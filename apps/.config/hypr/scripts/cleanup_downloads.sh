#!/bin/bash

# Define the target directory
TARGET_DIR="$HOME/Downloads"

# Check if directory exists just to be safe
if [ -d "$TARGET_DIR" ]; then
    # Find files older than 7 days and delete them
    # -mindepth 1: Ensures we don't delete the folder itself
    # -mtime +7: Looks for files modified more than 7 days ago
    # -delete: The action to take
    find "$TARGET_DIR" -mindepth 1 -mtime +7 -delete
fi
