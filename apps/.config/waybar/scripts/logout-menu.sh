#!/usr/bin/env bash

# Path to the new config
config="$HOME/.config/rofi/powermenu.rasi"

# Actions with Icons (from your original upload)
lock="  Lock"
shutdown="  Shutdown"
reboot="  Reboot"
suspend="  Suspend"
hibernate="  Hibernate"
logout="  Logout"

# Variable passed to rofi
options="$lock\n$shutdown\n$reboot\n$suspend\n$hibernate\n$logout"

# Open Rofi
# -dmenu: dmenu mode
# -i: case insensitive
# -no-custom: forces user to select one of the options (safer for power menus)
selected_option=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -no-custom -config "${config}")

# Perform actions based on the selected option
case "$selected_option" in
    "$lock")
        hyprlock
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$hibernate")
        systemctl hibernate
        ;;
    "$logout")
        hyprctl dispatch exit 0
        ;;
esac