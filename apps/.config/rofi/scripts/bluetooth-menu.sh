#!/usr/bin/env bash

config="$HOME/.config/rofi/custom-configs/wifi-bluetooth.rasi"

# --- DATA FETCHING ---
get_all_devices() {
    # Use 'devices' without filter to show ALL discovered devices (paired + scanned)
    # This is how rofi-bluetooth detects all available devices
    bt-device -l | awk "NR>1" | while read -r line; do
        mac=$(echo "$line" | grep -oP '\([0-9A-F:]+\)$' | tr -d '()')
        name=$(echo "$line" | sed 's/ *(.*$//' | xargs)
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
    [[ "$1" == "1" ]] && echo "󰂱" || echo " "
}

get_info() {
    local connected_devices=$(bt-device -l)
    if [ -n "$connected_devices" ]; then
        local first_device=$(echo "$connected_devices" | head -1 | cut -d ' ' -f 3-)
        echo "󰂱 Connected: $first_device"
    else
        echo "󰂲 Disconnected"
    fi
}

get_device_list() {
    while IFS='|' read -r mac name; do
        local device_info=$(bt-device -i "$mac")
        local connected=$(echo "$device_info" | grep "Connected:" | awk '{print $2}')
        local icon_type=$(echo "$device_info" | grep "Icon:" | awk '{print $2}')
        local device_icon=$(get_device_icon "$icon_type")
        local conn_icon=$(get_connection_icon "$connected")
        printf "%s %s  %s\n" "$device_icon" "$conn_icon" "$name"
    done < <(get_all_devices)
}

# --- MAIN LOOP ---
while true; do
    bt_status=$(bt-adapter -i | grep "Powered:" | awk '{print $2}')
    info_row=$(get_info)
    enable="󰂯 Enable Bluetooth"
    disable="󰂲 Disable Bluetooth"
    rescan="󰓦 Scan for Devices"
    sep="-----------------DEVICES-----------------"

    if [[ "$bt_status" == "1" ]]; then
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
            bt-adapter --set Powered 1
            sleep 1 # Give it a second to initialize
            ;;
        "$disable")
            bt-adapter --set Powered 0
            ;;
        "$rescan")
            notify-send "Bluetooth" "Scanning..."
            # Scan for 5 seconds in the foreground so the user sees the delay, 
            # then the loop refreshes the list
            timeout 5 bt-adapter -d
            notify-send "Bluetooth" "Scan complete"
            ;;
        *)
            device_name=$(echo "$selected" | sed 's/^.*  //')
            device_mac=$(bt-device -l | grep "$device_name" | grep -oP '\([0-9A-F:]+\)$' | tr -d '()')
            
            if [ -z "$device_mac" ]; then
                notify-send "Bluetooth" "Error: Could not find device"
                continue
            fi
            
            connected=$(bt-device -i "$device_mac" | grep "Connected:" | awk '{print $2}')
            device_path=$(echo "$device_mac" | sed 's/:/_/g')
            
            if [[ "$connected" == "1" ]]; then
                gdbus call --system --dest org.bluez --object-path /org/bluez/hci0/dev_${device_path} --method org.bluez.Device1.Disconnect
                notify-send "Bluetooth" "Disconnected $device_name"
            else
                notify-send "Bluetooth" "Connecting to $device_name..."
                
                # Trust and connect via D-Bus
                gdbus call --system --dest org.bluez --object-path /org/bluez/hci0/dev_${device_path} --method org.freedesktop.DBus.Properties.Set org.bluez.Device1 Trusted "<true>"
                gdbus call --system --dest org.bluez --object-path /org/bluez/hci0/dev_${device_path} --method org.bluez.Device1.Connect
                
                sleep 2
                new_status=$(bt-device -i "$device_mac" | grep "Connected:" | awk '{print $2}')
                if [[ "$new_status" == "1" ]]; then
                    notify-send "Bluetooth" "Connected to $device_name"
                else
                    notify-send "Bluetooth" "Failed to connect to $device_name"
                fi
            fi
            sleep 1
            ;;
    esac
done