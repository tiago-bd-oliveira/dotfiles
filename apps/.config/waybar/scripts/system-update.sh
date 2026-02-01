#!/usr/bin/env bash

# Check release
if [ ! -f /etc/arch-release ]; then
  exit 0
fi

pkg_installed() {
  local pkg=$1
  if pacman -Qi "${pkg}" &>/dev/null; then
    return 0
  elif pacman -Qi "flatpak" &>/dev/null && flatpak info "${pkg}" &>/dev/null; then
    return 0
  elif command -v "${pkg}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

get_aur_helper() {
  if pkg_installed yay; then
    aur_helper="yay"
  elif pkg_installed paru; then
    aur_helper="paru"
  fi
}

get_aur_helper
export -f pkg_installed
flatpak_update_cmd="pkg_installed flatpak && flatpak update"

# --- UPDATE CHECKS (Moved up so we can use the variables) ---
aur_updates=$(${aur_helper} -Qu 2>/dev/null | wc -l)
official_updates=$(checkupdates 2>/dev/null | wc -l)

if command -v flatpak >/dev/null; then
  flatpak_updates=$(nice -n 19 flatpak remote-ls --updates --columns=name 2>/dev/null | wc -l)
else
  flatpak_updates=0
fi

total_updates=$((official_updates + aur_updates + flatpak_updates))

# --- TRIGGER UPGRADE ---
if [ "$1" == "up" ]; then
  # Only launch the terminal if there is actually something to do
  if [ "$total_updates" -gt 0 ]; then
    trap 'pkill -RTMIN+20 waybar' EXIT
    command="
      $0 upgrade
      ${aur_helper} -Syu
      $flatpak_update_cmd

      printf '\n--- Updating package lists ---\n'
      ${aur_helper} -Qqen > ~/.dotfiles/system/packages.list
      ${aur_helper} -Qqem > ~/.dotfiles/system/aur-packages.list
      git -C ~/.dotfiles/ commit -am 'Update package lists'
      git -C ~/.dotfiles/ push

      printf '\n--- Cleaning up ---\n'
      flatpak uninstall --unused -y
      sudo paccache -r -k 2
      printf '\n'
      read -n 1 -p 'Done! Press any key to close...'
      "
    kitty --title "󰞒  System Update & Cleanup" sh -c "${command}"
    exit 0
  else
    # Optional: Send a notification if you click and nothing is there
    notify-send "System Update" "Your system is already up to date!" --icon=system-software-update
    exit 0
  fi
fi

# Output for Waybar/Upgrade summary
[ "${1}" == upgrade ] && printf "Official:   %-10s\nAUR ($aur_helper):  %-10s\nFlatpak:    %-10s\n\n" "$official_updates" "$aur_updates" "$flatpak_updates" && exit

tooltip="Official:   $official_updates\nAUR ($aur_helper):  $aur_updates\nFlatpak:    $flatpak_updates"

if [ $total_updates -eq 0 ]; then
  echo "{\"text\":\"󰸟\", \"tooltip\":\"Packages are up to date\"}"
else
  echo "{\"text\":\"󰞒\", \"tooltip\":\"${tooltip}\"}"
fi