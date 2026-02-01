#!/usr/bin/env bash

config="$HOME/.config/rofi/wifi-bluetooth.rasi"

# --- DATA FETCHING (The "Fast" Way) ---
# Fields: 1:ACTIVE, 2:SIGNAL, 3:SSID, 4:RATE, 5:SECURITY
# Sort by Rate (k4) then Signal (k2) to ensure the best AP is kept by awk
wifi_data=$(nmcli -t -f ACTIVE,SIGNAL,SSID,RATE,SECURITY device wifi list | sort -t: -k4,4rn -k2,2rn)
interface=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')

get_signal_icon() {
    local sig=$1
    if [ "$sig" -ge 80 ]; then echo "󰤨";
    elif [ "$sig" -ge 60 ]; then echo "󰤥";
    elif [ "$sig" -ge 40 ]; then echo "󰤢";
    elif [ "$sig" -ge 20 ]; then echo "󰤟";
    else echo "󰤯"; fi
}

get_info() {
    if [ -n "$interface" ]; then
        local ip=$(nmcli -g IP4.ADDRESS device show "$interface" | cut -d/ -f1)
        local rate=$(echo "$wifi_data" | grep '^yes' | cut -d: -f4)
        [ -n "$ip" ] && echo "󰩟  $ip  |  󰓅  $rate" || echo "󱚼  Offline"
    else
        echo "󰂭  No WiFi Device"
    fi
}

get_wifi_list() {
    # Filter: No empty SSIDs, then only unique SSIDs (keeping best rate/signal)
    echo "$wifi_data" | awk -F: '$3!="" && !seen[$3]++' | while IFS=: read -r active signal ssid rate security; do
        local icon=$(get_signal_icon "$signal")
        [[ "$active" == "yes" ]] && icon="$icon " || icon="$icon  "
        [ -z "$security" ] && security="Open"
        printf "%s  %-22s  %s\n" "$icon" "$ssid" "($security)"
    done
}

# --- UI PREPARATION ---
wifi_status=$(nmcli radio wifi)
info_row=$(get_info)
enable="󰤨 Enable Wi-Fi"
disable="󰤭 Disable Wi-Fi"
rescan="󰓦 Rescan"
manual=" Manual Entry"
sep="-----------AVAILABLE NETWORKS------------"

if [[ "$wifi_status" == "enabled" ]]; then
    menu="$info_row\n$disable\n$rescan\n$manual\n$sep\n$(get_wifi_list)"
else
    menu="$enable"
fi

selected=$(echo -e "$menu" | rofi -dmenu -i -p "Wifi" -config "${config}")

# Exit triggers
[ -z "$selected" ] && exit
[[ "$selected" == "$info_row" || "$selected" == "$sep" ]] && exit

case "$selected" in
    "$enable") nmcli radio wifi on && notify-send "Wi-Fi" "Enabled" ;;
    "$disable") nmcli radio wifi off && notify-send "Wi-Fi" "Disabled" ;;
    "$rescan") 
        notify-send "Wi-Fi" "Rescanning..."
        nmcli device wifi rescan
        ;;
    "$manual")
        manual_ssid=$(rofi -dmenu -p "Enter SSID" -config "${config}")
        [ -z "$manual_ssid" ] && exit
        pass=$(rofi -dmenu -password -p "Password" -config "${config}")
        nmcli device wifi connect "$manual_ssid" password "$pass"
        ;;
    *)
        # --- EXTRACTION ---
        chosen_ssid=$(echo "$selected" | sed -E 's/^.{6}//; s/  \(.*//' | xargs)
        security_info=$(echo "$selected" | grep -oP '\(.*\)')

        # --- CONNECTION LOGIC ---
        if nmcli -t -f NAME connection show | grep -x "$chosen_ssid" > /dev/null; then
            notify-send "Wi-Fi" "Connecting to saved network: $chosen_ssid..."
            nmcli connection up id "$chosen_ssid" && notify-send "Wi-Fi" "Connected" || notify-send "Wi-Fi" "Failed"
        else
            # New Network Path
            if [[ "$security_info" == "(Open)" || "$security_info" == "()" ]]; then
                notify-send "Wi-Fi" "Connecting to open network..."
                nmcli device wifi connect "$chosen_ssid" && notify-send "Wi-Fi" "Connected"
            elif [[ "$security_info" =~ "802.1X" || "$security_info" =~ "EAP" ]]; then
                # Enterprise/University Path
                user=$(rofi -dmenu -p "Username" -config "${config}")
                pass=$(rofi -dmenu -password -p "Password" -config "${config}")
                [ -z "$user" ] && exit
                notify-send "Wi-Fi" "Authenticating..."
                nmcli device wifi connect "$chosen_ssid" 802-1x.identity "$user" 802-1x.password "$pass" 802-1x.key-mgmt wpa-eap && notify-send "Wi-Fi" "Connected"
            else
                # Standard WPA Path
                pass=$(rofi -dmenu -password -p "Password" -config "${config}")
                if [ -n "$pass" ]; then
                    notify-send "Wi-Fi" "Connecting..."
                    nmcli device wifi connect "$chosen_ssid" password "$pass" && notify-send "Wi-Fi" "Connected" || notify-send "Wi-Fi" "Auth Failed"
                fi
            fi
        fi
        ;;
esac