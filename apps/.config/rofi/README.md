# Rofi Configuration

Simple, clean Rofi configuration organized for your system.

## Directory Structure

```
~/.config/rofi/
├── config.rasi              Main Rofi configuration
├── powermenu.rasi           Power menu theme
├── wifi-bluetooth.rasi      WiFi/Bluetooth menu theme
├── colors/                  Color schemes (16 available)
├── scripts/
│   ├── powermenu.sh        Power menu launcher
│   └── wifi-menu.sh        WiFi menu launcher
└── README.md               This file
```

## Quick Commands

```bash
# Launch application menu
rofi -show drun -config ~/.config/rofi/config.rasi

# Power menu
~/.config/rofi/scripts/powermenu.sh

# WiFi menu
~/.config/rofi/scripts/wifi-menu.sh
```

## Configuration

### Change Theme

Edit `config.rasi` line 12:
```rasi
@theme "/home/quexumo/.local/share/rofi/themes/squared-nord.rasi"
```

Available themes in `~/.local/share/rofi/themes/`:
- squared-nord, nord, launchpad, windows11-*, spotlight, rounded-*, etc.

### Change Color Scheme

Uncomment in `config.rasi`:
```rasi
@import "~/.config/rofi/colors/nord.rasi"
```

Available colors: adapta, arc, black, catppuccin, cyberpunk, dracula, everforest, gruvbox, lovelace, navy, nord, onedark, paper, solarized, tokyonight, yousai

### Modify Power Menu

Edit `scripts/powermenu.sh` to add/remove options and commands.

### Modify WiFi Menu

Edit `scripts/wifi-menu.sh` to customize WiFi menu behavior.

## Add to Window Manager

Example for Hyprland in `~/.config/hypr/hyprland.conf`:

```conf
bind = SUPER, space, exec, rofi -show drun
bind = SUPER, escape, exec, ~/.config/rofi/scripts/powermenu.sh
bind = SUPER, w, exec, ~/.config/rofi/scripts/wifi-menu.sh
```

## Available Options in config.rasi

- `modi` - Enabled modes (drun, run, filebrowser, window, etc.)
- `show-icons` - Show application icons
- `icon-theme` - Icon theme to use
- `font` - Font and size
- Display names for each mode
- Keybindings (mostly commented, customize as needed)

See the `config.rasi` file directly for all available settings.

## Tips

1. **Test changes**: `rofi -config ~/.config/rofi/config.rasi -show drun`
2. **View all settings**: `rofi -dump-config`
3. **List fonts**: `fc-list | grep "Font Name"`
4. **Check themes**: `ls ~/.local/share/rofi/themes/`

## Troubleshooting

Scripts won't run?
```bash
chmod +x ~/.config/rofi/scripts/*.sh
```

Theme not found?
```bash
ls ~/.local/share/rofi/themes/squared-nord.rasi
```

Rofi test:
```bash
rofi -dump-config 2>&1 | head
```
