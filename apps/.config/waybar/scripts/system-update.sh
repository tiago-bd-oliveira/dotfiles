#!/usr/bin/env bash

# Check release
if [ ! -f /etc/arch-release ]; then
  exit 0
fi

# Counts are cached here by the periodic waybar run, so the click path
# ("up") and the in-terminal summary ("upgrade") don't have to redo the
# network checks. Lives on tmpfs, so it resets on reboot.
cache_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-system-update.count"

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
flatpak_update_cmd="pkg_installed flatpak && flatpak update -y"

# --- UPDATE CHECKS ---
# Each of these hits the network (AUR RPC, mirror db sync, flatpak remotes)
# and together they take a couple of seconds, so only run them when we
# actually need fresh numbers.
run_checks() {
  aur_updates=$(${aur_helper} -Qu 2>/dev/null | wc -l)
  official_updates=$(checkupdates 2>/dev/null | wc -l)

  if command -v flatpak >/dev/null; then
    flatpak_updates=$(nice -n 19 flatpak remote-ls --updates --columns=name 2>/dev/null | wc -l)
  else
    flatpak_updates=0
  fi

  total_updates=$((official_updates + aur_updates + flatpak_updates))
  printf '%s %s %s\n' "$official_updates" "$aur_updates" "$flatpak_updates" >"$cache_file"
}

# Populate the counts from cache; fall back to a live check if it's missing
# or malformed (e.g. first run after boot).
load_counts() {
  if [ -r "$cache_file" ]; then
    read -r official_updates aur_updates flatpak_updates <"$cache_file"
  fi

  case "${official_updates}${aur_updates}${flatpak_updates}" in
  '' | *[!0-9]*)
    run_checks
    return
    ;;
  esac

  total_updates=$((official_updates + aur_updates + flatpak_updates))
}

# --- TRIGGER UPGRADE ---
if [ "$1" == "up" ]; then
  load_counts

  # Only launch the terminal if there is actually something to do
  if [ "$total_updates" -gt 0 ]; then
    trap 'pkill -RTMIN+20 waybar' EXIT
    command="
      $0 upgrade
      ${aur_helper} -Syu --noconfirm
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
if [ "${1}" == upgrade ]; then
  load_counts
  printf "Official:   %-10s\nAUR ($aur_helper):  %-10s\nFlatpak:    %-10s\n\n" "$official_updates" "$aur_updates" "$flatpak_updates"
  exit
fi

run_checks

tooltip="Official:   $official_updates\nAUR ($aur_helper):  $aur_updates\nFlatpak:    $flatpak_updates"

if [ $total_updates -eq 0 ]; then
  echo "{\"text\":\"󰸟\", \"tooltip\":\"Packages are up to date\"}"
else
  echo "{\"text\":\"󰞒\", \"tooltip\":\"${tooltip}\"}"
fi
