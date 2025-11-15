#!/bin/bash

MONITOR="DP-1"
RESOLUTION="3840x2160@239.99"

# Function to get the current focused window class
get_focused_class() {
    hyprctl activewindow -j | jq -r '.class'
}

# Track previous state
previous_minecraft_focused=false

while true; do
    focused_class=$(get_focused_class)
    
    # Check if Minecraft/Java window is focused
    if [[ "$focused_class" =~ waywall ]]; then
        if [ "$previous_minecraft_focused" = false ]; then
            # Minecraft just got focused, set scale to 1
            hyprctl keyword monitor $MONITOR,$RESOLUTION,auto,1
            previous_minecraft_focused=true
        fi
    else
        if [ "$previous_minecraft_focused" = true ]; then
            # Minecraft just lost focus, set scale to 2
            hyprctl keyword monitor $MONITOR,$RESOLUTION,auto,2
            previous_minecraft_focused=false
        fi
    fi
    
    sleep 0.1
done
