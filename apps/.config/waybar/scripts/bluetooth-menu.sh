#!/usr/bin/env bash

# --- CONFIGURATION ---
# Point this to the specific Adi1090x theme you want to use.
# Example: ~/.config/rofi/launchers/type-1/style-5.rasi
config="$HOME/.config/rofi/config.rasi"

# Initial notification
notify-send "Bluetooth" "Searching for available devices..."

while true; do
  # Check Bluetooth status
  bluetooth_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

  if [[ "$bluetooth_status" == "yes" ]]; then
    # Fetch available devices (names only)
    bluetooth_devices=$(bluetoothctl devices | awk '{$1=$2=""; print substr($0, 3)}')
    
    # We add the "Rescan" and "Disable" options
    options=" 󰂰  Rescan\n 󰂲  Disable Bluetooth\n$(echo "$bluetooth_devices" | awk '{print " 󰂱  " $0}')"
    
    # OVERRIDE 1: When Bluetooth is ON
    # We force the input bar to have a placeholder. 
    # We do NOT force height here, we let the Adi1090x theme decide.
    override="entry { placeholder: \"Search Devices...\"; }"
    
  else
    options=" 󰂯  Enable Bluetooth"
    
    # OVERRIDE 2: When Bluetooth is OFF
    # We hide the listview (the results area) so only the input/message shows.
    override="listview { enabled: false; } entry { placeholder: \"Bluetooth is Off\"; }"
  fi

  # --- LAUNCH ROFI ---
  # We use -theme-str to apply our small tweaks on top of the beautiful Adi theme
  selected_option=$(echo -e "$options" | rofi -dmenu -i -selected-row 1 -config "${config}" -theme-str "${override}")

  # Exit if no option is selected
  if [ -z "$selected_option" ]; then
    exit
  fi

  # --- ACTIONS ---
  case "$selected_option" in
  " 󰂯  Enable Bluetooth")
    notify-send "Bluetooth" "Enabled"
    rfkill unblock bluetooth
    bluetoothctl power on
    sleep 1
    ;;
  " 󰂲  Disable Bluetooth")
    notify-send "Bluetooth" "Disabled"
    rfkill block bluetooth
    bluetoothctl power off
    sleep 1
    ;;
  " 󰂰  Rescan")
    notify-send "Bluetooth" "Rescanning..."
    bluetoothctl scan on
    sleep 3
    bluetoothctl scan off
    notify-send "Bluetooth" "Scan completed"
    ;;
  *)
    # Extract device name
    device_name=${selected_option// 󰂱  /}

    if [[ -n "$device_name" ]]; then
      device_mac=$(bluetoothctl devices | grep "$device_name" | awk '{print $2}')

      notify-send "Bluetooth" "Connecting to $device_name..."
      bluetoothctl connect "$device_mac" &
      sleep 3

      connection_status=$(bluetoothctl info "$device_mac" | grep "Connected:" | awk '{print $2}')

      if [[ "$connection_status" == "yes" ]]; then
        notify-send "Bluetooth" "Connected to $device_name"
      else
        notify-send "Bluetooth" "Connection failed"
      fi
    fi
    ;;
  esac
done