#!/bin/bash

# 1. Check for required arguments
if [ $# -eq 0 ]; then
  echo "[-] Error: Missing arguments."
  echo "    Usage: $0 <IP_ADDRESS/MASK> [LAN_NAME]"
  echo "    Example: $0 192.168.100.29/24 lanA"
  exit 1
fi

IP_CIDR=$1
LAN_NAME=$2

# 2. Basic validation for the IP/Mask format (IPv4 or IPv6)
# Checks for IPv4 (x.x.x.x/y) OR IPv6 (xxxx:xxxx::xxxx/y)
if [[ ! $IP_CIDR =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] && [[ ! $IP_CIDR =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
  echo "[-] Error: Invalid IP/Mask format."
  echo "    Please use CIDR notation for IPv4 (e.g., 10.0.0.2/24) or IPv6 (e.g., 2001:db8:cafe:1::101/64)."
  exit 1
fi

# 3. Find the Docker network bridge for the lab
if [ -z "$LAN_NAME" ]; then
  echo "[*] No LAN provided. Searching for the first available Kathará network..."
  # Grabs the short ID of the first Kathará network it finds
  bridge_id="$(sudo docker network ls | grep -oP '^[a-z0-9]+(?=\s+kathara_)' | head -n 1)"
  LAN_NAME="(default)"
else
  echo "[*] Searching for LAN: $LAN_NAME..."
  # Uses awk to reliably grab just the ID column
  bridge_id="$(sudo docker network ls | grep "kathara_${USER}.*_${LAN_NAME}" | awk '{print $1}')"
fi

# 4. Verify if a bridge was actually found
if [ -z "$bridge_id" ]; then
  echo "[-] Error: Could not find an active network for LAN '$LAN_NAME'."
  echo "    Make sure the lab is currently running (kathara lstart)."
  exit 1
fi

# Construct the bridge name based on the original script logic
bridge_name="kt-${bridge_id}"
echo "[+] Found target bridge: $bridge_name"
echo "[*] Configuring virtual interfaces (veth0 <--> veth1)..."

# 5. Clean up old interfaces silently (redirects stderr to /dev/null so it doesn't print ugly errors)
sudo ip link del veth1 type veth 2>/dev/null

# 6. Create new veth pair
sudo ip link add veth1 type veth

# 7. Flush old IPs and attempt to assign the new one
sudo ip addr flush dev veth0 2>/dev/null

if ! sudo ip addr add "$IP_CIDR" dev veth0 2>/dev/null; then
  echo "[-] Error: Failed to assign $IP_CIDR to veth0. Check your IP/Mask syntax."
  exit 1
fi

# 8. Attach to the Kathará bridge
if ! sudo ip link set veth1 master "$bridge_name" 2>/dev/null; then
  echo "[-] Error: Failed to attach veth1 to $bridge_name."
  echo "    (Tip: If 'kt-' doesn't exist, Docker might be using the default 'br-${bridge_id}' format)."
  exit 1
fi

# 9. Bring interfaces up
sudo ip link set veth0 up
sudo ip link set veth1 up

echo "[+] Success! Host is now connected to $LAN_NAME via veth0 ($IP_CIDR)."
