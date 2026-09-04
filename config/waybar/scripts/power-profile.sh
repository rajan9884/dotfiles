#!/usr/bin/env bash
# Shows the active power profile for the waybar module; click opens the switcher.

case "$(powerprofilesctl get 2>/dev/null)" in
    performance) echo "󰓅 perf" ;;
    power-saver) echo "󰾆 save" ;;
    *) echo "󰾅 bal" ;;
esac