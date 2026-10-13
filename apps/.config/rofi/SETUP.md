# Rofi Configuration - Refactoring Complete

## Simple, Clean Structure

```
~/.config/rofi/
├── config.rasi              Main configuration
├── powermenu.rasi           Power menu theme
├── wifi-bluetooth.rasi      WiFi menu theme
├── colors/                  Color schemes (optional)
├── scripts/
│   ├── powermenu.sh        Power menu (from waybar)
│   └── wifi-menu.sh        WiFi menu (from waybar)
└── README.md
```

## What You Have

✓ **config.rasi** - Main rofi config for app launcher and run menu
✓ **powermenu.rasi** - Custom power menu theme
✓ **wifi-bluetooth.rasi** - Custom WiFi/Bluetooth menu theme
✓ **scripts/powermenu.sh** - Power menu launcher
✓ **scripts/wifi-menu.sh** - WiFi menu launcher (copied from waybar)
✓ **colors/** - Directory for color schemes (16 schemes available)
✓ **README.md** - Quick reference guide

## Quick Commands

```bash
# Test rofi launcher
rofi -show drun -config ~/.config/rofi/config.rasi

# Power menu
~/.config/rofi/scripts/powermenu.sh

# WiFi menu
~/.config/rofi/scripts/wifi-menu.sh
```

## What Changed

**Removed:**
- Unnecessary launcher/applet/powermenu type variations
- Overcomplicated directory structure
- Duplicate documentation

**Kept:**
- Your actual config files (config.rasi, powermenu.rasi, wifi-bluetooth.rasi)
- Your waybar scripts (powermenu, wifi-menu)
- Color schemes directory
- Simple, maintainable structure

**Added:**
- `/scripts/powermenu.sh` - Clean power menu script
- `/scripts/wifi-menu.sh` - WiFi menu script (from waybar)
- `/README.md` - Simple reference guide

## Customization

**Change theme:**
```bash
# Edit config.rasi line 12
@theme "/home/quexumo/.local/share/rofi/themes/nord.rasi"
```

**Change color scheme:**
```bash
# Uncomment in config.rasi
@import "~/.config/rofi/colors/nord.rasi"
```

**Customize power menu:**
```bash
# Edit scripts/powermenu.sh to change options/commands
```

**Customize WiFi menu:**
```bash
# Edit scripts/wifi-menu.sh
```

## Hyprland Integration

Add to `~/.config/hypr/hyprland.conf`:

```conf
bind = SUPER, space, exec, rofi -show drun
bind = SUPER, escape, exec, ~/.config/rofi/scripts/powermenu.sh
bind = SUPER, w, exec, ~/.config/rofi/scripts/wifi-menu.sh
```

## Files You May Still Want to Check

- `~/.config/waybar/scripts/` - Your other scripts (brightness, volume, media, etc.)
- `~/.local/share/rofi/themes/` - Available system themes

---

**Status**: ✓ Refactoring Complete  
**Complexity**: Minimal - Just what you need  
**Ready to Use**: Yes
