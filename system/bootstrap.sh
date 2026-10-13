#!/bin/bash

echo "Starting system bootstrap..."

# 1. Update system
sudo pacman -Syu --noconfirm

# 2. Install packages from list
sudo pacman -S --needed - < ~/.dotfiles/system/packages.list

echo "Bootstrap complete!"
