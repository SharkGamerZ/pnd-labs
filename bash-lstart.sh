#!/bin/bash

# Start Kathará in privileged mode
sudo kathara lstart --privileged

# Parse lab.conf for all device names
# This regex grabs any alphanumeric string immediately preceding a '['
# (e.g., it grabs 'lan1pc1' from 'lan1pc1[0]="A"')
devices=$(grep -oP '[a-zA-Z0-9]+(?=\[)' lab.conf | sort --unique)

# Loop through each unique device found
for device in $devices; do
  # Determine the background color based on wildcard matching of the name
  case "$device" in
  r[0-9]*) bg_color="#1a1e24" ;;         # Router: Server Rack Slate
  *pc[0-9]*) bg_color="#001a33" ;;       # PC (matches pc1, lan1pc1): Dark Blue
  s[0-9]*) bg_color="#3d3000" ;;         # Server: Dark Gold / Mustard
  fw[0-9]*) bg_color="#002b11" ;;        # Firewall: Deep Forest Green
  isp | isp[0-9]*) bg_color="#1a0033" ;; # ISP: Deep Purple
  rw[0-9]*) bg_color="#002b2b" ;;        # Road Warrior: Deep Teal
  a[0-9]*) bg_color="#380000" ;;         # Attacker: Deep Threat Red
  *) bg_color="#111111" ;;               # Fallback for unknown: Dark Grey
  esac

  # Launch Kitty with the assigned color and the -l flag to show startup logs
  kitty --class kathara_lab -T "$device" \
    -o background="$bg_color" \
    -o foreground="#ffffff" \
    -- bash -c "kathara connect -l $device" 2>/dev/null &
done
