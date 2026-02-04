#!/usr/bin/env bash

# Power menu script - wrapper around waybar's logout menu
config="$HOME/.config/rofi/custom-configs/powermenu.rasi"

lock="  Lock"
shutdown="  Shutdown"
reboot="  Reboot"
suspend="  Suspend"
hibernate="  Hibernate"
logout="  Logout"

options="$lock\n$shutdown\n$reboot\n$suspend\n$hibernate\n$logout"

selected_option=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -no-custom -config "${config}")

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
