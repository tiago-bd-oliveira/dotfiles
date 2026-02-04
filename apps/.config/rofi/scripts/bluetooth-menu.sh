#!/usr/bin/env bash

config="$HOME/.config/rofi/custom-configs/wifi-bluetooth.rasi"

# --- DATA FETCHING ---
get_all_devices() {
    # Use 'devices' without filter to show ALL discovered devices (paired + scanned)
    # This is how rofi-bluetooth detects all available devices
    bluetoothctl devices | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f 3-)
        echo "$mac|$name"
    done
}

get_device_icon() {
    local icon_type="$1"
    
    # Map bluetoothctl Icon types to Nerd Font icons
    case "$icon_type" in
        audio-headphones)  echo "󰋋" ;;
        audio-headset)     echo "󰋎" ;;
        audio-card|audio-speakers) echo "󰓃" ;;
        input-keyboard)    echo "󰌌" ;;
        input-mouse)       echo "󰍽" ;;
        input-gaming)      echo "󰊗" ;;
        phone)             echo "�" ;;
        computer)          echo "󰟀" ;;
        video-display|display) echo "󰍹" ;;
        camera-photo)      echo "󰄀" ;;
        printer)           echo "󰐪" ;;
        *)                 echo "󰂯" ;;  # Generic bluetooth for unknown
    esac
}

get_connection_icon() {
    [[ "$1" == "yes" ]] && echo "󰂱" || echo " "
}

get_info() {
    local connected_devices=$(bluetoothctl devices Connected)
    if [ -n "$connected_devices" ]; then
        local first_device=$(echo "$connected_devices" | head -1 | cut -d ' ' -f 3-)
        echo "󰂱 Connected: $first_device"
    else
        echo "󰂲 Disconnected"
    fi
}

get_device_list() {
    while IFS='|' read -r mac name; do
        local device_info=$(bluetoothctl info "$mac")
        local connected=$(echo "$device_info" | grep "Connected:" | awk '{print $2}')
        local icon_type=$(echo "$device_info" | grep "Icon:" | awk '{print $2}')
        local device_icon=$(get_device_icon "$icon_type")
        local conn_icon=$(get_connection_icon "$connected")
        printf "%s %s  %s\n" "$device_icon" "$conn_icon" "$name"
    done < <(get_all_devices)
}

# --- MAIN LOOP ---
while true; do
    bt_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
    info_row=$(get_info)
    enable="󰂯 Enable Bluetooth"
    disable="󰂲 Disable Bluetooth"
    rescan="󰓦 Scan for Devices"
    sep="-----------------DEVICES-----------------"

    if [[ "$bt_status" == "yes" ]]; then
        menu="$info_row\n$disable\n$rescan\n$sep\n$(get_device_list)"
    else
        menu="$enable"
    fi

    selected=$(echo -e "$menu" | rofi -dmenu -i -p "Bluetooth" -config "${config}" -a 0)

    # Exit if user hits Escape
    [ -z "$selected" ] && exit

    # Ignore clicks on the info row or separator
    [[ "$selected" == "$info_row" || "$selected" == "$sep" ]] && continue

    case "$selected" in
        "$enable")
            bluetoothctl power on
            sleep 1 # Give it a second to initialize
            ;;
        "$disable")
            bluetoothctl power off
            ;;
        "$rescan")
            notify-send "Bluetooth" "Scanning..."
            # Scan for 5 seconds in the foreground so the user sees the delay, 
            # then the loop refreshes the list
            bluetoothctl --timeout 5 scan on
            notify-send "Bluetooth" "Scan complete"
            ;;
        *)
            # Extract device name (after icons and double space)
            device_name=$(echo "$selected" | sed 's/^.*  //')
            # Look up MAC address by device name
            device_mac=$(bluetoothctl devices | grep " $device_name$" | awk '{print $2}')
            
            connected=$(bluetoothctl info "$device_mac" | grep "Connected:" | awk '{print $2}')
            
            if [[ "$connected" == "yes" ]]; then
                bluetoothctl disconnect "$device_mac"
                notify-send "Bluetooth" "Disconnected $device_name"
            else
                notify-send "Bluetooth" "Connecting to $device_name..."
                bluetoothctl connect "$device_mac"
            fi
            sleep 1 # Small delay for the status to update before loop refreshes
            ;;
    esac
done