# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os

import libqtile.resources
from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

import sys
import subprocess

from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration

mod = "mod4"
# terminal = guess_terminal()
terminal = "kitty"

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),

    # Volume Controls
    Key([], "XF86AudioMute", lazy.spawn("pamixer -t")),
    Key([], "XF86AudioLowerVolume", lazy.spawn("pamixer -d 5")),
    Key([], "XF86AudioRaiseVolume", lazy.spawn("pamixer -i 5")),

    # Screen Brightness
    Key([], "XF86MonBrightnessDown", lazy.spawn("brightnessctl set 5%-")),
    Key([], "XF86MonBrightnessUp", lazy.spawn("brightnessctl set 5%+")),

    # Media Controls
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="Play/Pause player"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="Skip to next"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"), desc="Skip to previous"),
    Key([], "XF86AudioStop", lazy.spawn("playerctl stop"), desc="Stop player"),

    # Shortcuts
    Key([mod], "b", lazy.spawn("firefox"), desc="Open firefox"),
    Key([mod, "shift"], "b", lazy.spawn("firefox --private-window"), desc="Open firefox on incognito"),
    Key([mod], "m", lazy.spawn("flatpak run com.spotify.Client"), desc="open spotify"),
    Key([mod], "space", lazy.spawn("ulauncher-toggle"))
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )


groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            # mod + shift + group number = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc=f"Switch to & move focused window to group {i.name}",
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod + shift + group number = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

colors = {
    "polar_night": "#2e3440",
    "polar_night_light": "#434c5e",
    "snow_storm":  "#d8dee9",
    "frost_1":     "#8fbcbb", # Teal
    "frost_2":     "#88c0d0", # Light Blue
    "frost_3":     "#81a1c1", # Blue
    "frost_4":     "#5e81ac", # Dark Blue
    "aurora_red":  "#bf616a",
    "aurora_green": "#a3be8c",
    "aurora_yellow": "#ebcb8b",
}

decoration_group = {
    "decorations": [
        RectDecoration(
            colour=colors["polar_night_light"],  # Background of the "capsule"
            radius=10,                           # Rounded corners (0 for square)
            filled=True,
            padding_y=4,                         # Shrink the capsule vertically
        )
    ],
    "padding": 10,  # Space between text and the edge of the capsule
}

layouts = [
    layout.Columns(
        border_focus=colors["frost_2"],     # Active window (Nord Blue)
        border_normal=colors["polar_night"],# Inactive window (Nord Dark Grey)
        border_focus_stack=colors["frost_2"], # Stacked window border
        border_width=4,
        margin=8,
    ),
    layout.Max(),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="sans",
    fontsize=18,
    padding=3,
)
extension_defaults = widget_defaults.copy()

logo = os.path.join(os.path.dirname(libqtile.resources.__file__), "logo.png")
screens = [
    Screen(
        top=bar.Bar(
            [
                # --- LEFT SIDE: WORKSPACES ---
                widget.Spacer(length=10),
                widget.GroupBox(
                    font="JetBrainsMono Nerd Font",
                    fontsize=14,
                    margin_y=3,
                    margin_x=0,
                    padding_y=5,
                    padding_x=10,
                    borderwidth=3,
                   active=colors["frost_2"],
                    inactive=colors["snow_storm"],
                    rounded=False,
                    highlight_method='line',
                    highlight_color=colors["polar_night_light"], # Match decoration
                    this_current_screen_border=colors["frost_3"],
                    this_screen_border=colors["frost_4"],
                    other_current_screen_border=colors["frost_3"],
                    other_screen_border=colors["frost_4"],
                    foreground=colors["snow_storm"],
                    **decoration_group # Apply the rounded background
                ),

                widget.Spacer(length=10),

                # --- CENTER: WINDOW TITLE ---
                widget.WindowName(
                    foreground=colors["snow_storm"],
                    format="{name}",
                    max_chars=50,
                    width=200, # Limit width so it doesn't take over
                    **decoration_group
                ),

                widget.Spacer(), # Push everything else to the right

                # --- RIGHT SIDE: MODULES ---
                
                # System Tray (Cannot be decorated nicely usually, keep separate)
                widget.Systray(padding=10),
                widget.Spacer(length=10), 

                widget.Mpris2(
                    name="mpris",
                    objname="org.mpris.MediaPlayer2.spotify", # <--- I REMOVED THIS
                    # Removing objname allows it to find ANY player (including Flatpak) automatically.
                    
                    display_metadata=['xesam:title', 'xesam:artist'],
                    stop_pause_text="Not Playing",
                    scroll_chars=None,
                    width=200,
                    foreground=colors["snow_storm"], # Changed from Red to your theme color
                    **decoration_group # Added your rounded decoration so it matches the other widgets!
                ),
                widget.Spacer(length=10),

                # Volume Capsule
                widget.Volume(
                    foreground=colors["snow_storm"],
                    background=colors["frost_4"],
                    fmt='Vol: {}',
                    # explicitly tell it how to check volume/mute status
                    get_volume_command='pamixer --get-volume-human',
                    padding=10
                ),
                widget.Spacer(length=10),

                # Clock Capsule
                widget.Clock(
                    format="  %H:%M",
                    foreground=colors["frost_1"],
                    **decoration_group
                ),
                widget.Spacer(length=10),

                # Battery/Power Capsule
                widget.QuickExit(
                    default_text='  ',
                    countdown_format=' {} ',
                    foreground=colors["aurora_red"],
                    **decoration_group
                ),
                widget.Spacer(length=10),

                
            ],
            36, # Bar Height (Slightly taller for floating look)
            background="#00000000", # Transparent main background (requires Picom!)
             margin=[5, 10, 0, 10], # [top, right, bottom, left] - FLOATING EFFECT
        ),
        wallpaper='~/pictures/wallpapers/paul-pastourmatzis-KT3WlrL_bsg-unsplash.jpg',
        wallpaper_mode='fill'
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    
    ],
    border_width=0
)
auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
2

@hook.subscribe.startup_once
def autostart():
    subprocess.Popen(['picom', '-b'])
    subprocess.Popen(['qbittorrent', '--no-splash'])
    subprocess.Popen('flameshot')
    subprocess.Popen("sleep 2 && ulauncher --hide-window --no-window-shadow", shell=True)    

