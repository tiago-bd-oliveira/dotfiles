#!/bin/bash

echo "Starting system bootstrap..."

# 1. Update system
sudo pacman -Syu --noconfirm

# 2. Install packages from list (only those in the repos; pacman aborts
#    everything if a single name isn't found)
sudo pacman -S --needed - < <(LC_ALL=C comm -12 \
  <(LC_ALL=C sort -u ~/.dotfiles/system/packages.list) \
  <(pacman -Slq | LC_ALL=C sort -u))

echo "Bootstrap complete!"
