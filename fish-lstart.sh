#!/usr/bin/fish

# Start Kathará in privileged mode, but tell it NOT to open terminals 
# (we will handle the terminals manually in the loop below)
sudo kathara lstart --privileged --noterminals

# Parse lab.conf for all device names
set devices (grep -oP '[a-zA-Z0-9]+(?=\[)' lab.conf | sort --unique)

# Loop through each unique device found
for device in $devices
    # Determine the background color (High-Contrast Palette)
    switch $device
        case 'r*'
            set bg_color "333333" # Router: Charcoal Grey (Neutral)
        case '*pc*'
            set bg_color "002266" # PC: Deep Royal Blue
        case 's*'
            set bg_color "4d3300" # Server: Dark Bronze
        case 'fw*'
            set bg_color "004411" # Firewall: Deep Forest Green
        case 'isp*'
            set bg_color "440044" # ISP: Deep Purple
        case 'rw*'
            set bg_color "004444" # Road Warrior: Deep Cyan
        case 'a*'
            set bg_color "550000" # Attacker: Blood Red
        case '*'
            set bg_color "111111" # Fallback: Near Black
    end

    # Launch Foot terminal with all colors-dark overrides
    foot --title="$device" \
        --override="colors-dark.background=$bg_color" \
        --override="colors-dark.foreground=ffffff" \
        --override="colors-dark.alpha=1.0" \
        fish -c "kathara connect -l $device" 2>/dev/null &
end
