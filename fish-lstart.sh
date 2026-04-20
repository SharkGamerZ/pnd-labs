#!/usr/bin/fish

# Start Kathará in privileged mode, but tell it NOT to open terminals 
# (we will handle the terminals manually in the loop below)
sudo kathara lstart --privileged --noterminals

# Parse lab.conf for all device names
set devices (grep -oP '[a-zA-Z0-9]+(?=\[)' lab.conf | sort --unique)

# Loop through each unique device found
for device in $devices
    switch $device
        case 'r[0-9]*'
            set bg_color "1a1e24"
        case '*pc[0-9]*'
            set bg_color "001a33"
        case 's[0-9]*'
            set bg_color "3d3000"
        case 'fw[0-9]*'
            set bg_color "002b11"
        case 'isp' 'isp[0-9]*'
            set bg_color "1a0033"
        case 'rw[0-9]*'
            set bg_color "002b2b"
        case 'a[0-9]*'
            set bg_color "380000"
        case '*'
            set bg_color "111111"
    end

    # Launch Foot terminal, redirecting errors to /dev/null for a clean output
    foot --title="$device" \
        --override="colors-dark.background=$bg_color" \
        --override="colors-dark.foreground=ffffff" \
        fish -c "kathara connect -l $device" 2>/dev/null &
end
