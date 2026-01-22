#!/bin/bash

SOCKET="/run/user/1000/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

# Get the default sensitivity from Hyprland config on startup
DEFAULT_SENSITIVITY=$(hyprctl getoption input:sensitivity -j | jq -r '.float')

handle() {
  case $1 in
    activewindow*)
      # Skip if it's just the address (no comma means no class,title pair)
      if echo "$1" | grep -q ","; then
        if echo "$1" | grep -qi "waywall,waywall"; then
          hyprctl keyword input:sensitivity -0.75
        else
          hyprctl keyword input:sensitivity "$DEFAULT_SENSITIVITY"
        fi
      fi
      ;;
  esac
}

socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do handle "$line"; done
