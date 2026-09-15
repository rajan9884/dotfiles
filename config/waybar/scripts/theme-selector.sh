#!/usr/bin/env bash

# Waybar Theme Selector Script

THEMES_DIR="$HOME/.config/waybar/themes"
WAYBAR_DIR="$HOME/.config/waybar"

# Ensure the themes directory exists
if [ ! -d "$THEMES_DIR" ]; then
    notify-send "Error" "Themes directory not found at $THEMES_DIR"
    exit 1
fi

# List available themes by looking at directory names
THEMES=$(ls -1 "$THEMES_DIR")

# Use rofi to prompt the user
SELECTED=$(echo "$THEMES" | rofi -dmenu -i -p "Select Waybar Theme" -theme ~/.config/rofi/active-scripts.rasi)

# If a theme was selected
if [ -n "$SELECTED" ]; then
    # Create symlinks
    ln -sf "$THEMES_DIR/$SELECTED/config.jsonc" "$WAYBAR_DIR/config.jsonc"
    ln -sf "$THEMES_DIR/$SELECTED/style.css" "$WAYBAR_DIR/style.css"
    
    # Restart Waybar to apply the new theme
    killall -q waybar .waybar-wrapped 2>/dev/null || true
    waybar & disown
    
    notify-send "Waybar Theme Updated" "Switched to '$SELECTED' theme."
fi
