#!/bin/bash

# Script to configure NetworkManager VPN connection with certificate fingerprint
# This will allow the GNOME VPN toggle to work without certificate warnings

VPN_HOST="vpn.xxxxxxxxxx.edu"
VPN_NAME="vpn-xxxxxxxxxxxxx-edu"
SHA256_FINGERPRINT="Nxxxxxxxxxxxxxxxxxxxxxx="

# Check if the connection already exists
if nmcli connection show | grep -q "$VPN_NAME"; then
  echo "Modifying existing VPN connection '$VPN_NAME'..."
  
  # Update the existing connection
  nmcli connection modify "$VPN_NAME" \
    vpn.data "gateway=$VPN_HOST,servercert=pin-sha256:$SHA256_FINGERPRINT,protocol=anyconnect,no-cert-check=yes"
else
  echo "Creating new VPN connection '$VPN_NAME'..."
  
  # Create a new connection
  nmcli connection add \
    type vpn \
    vpn-type openconnect \
    con-name "$VPN_NAME" \
    ifname "*" \
    vpn.data "gateway=$VPN_HOST,servercert=pin-sha256:$SHA256_FINGERPRINT,protocol=anyconnect,no-cert-check=yes"
fi

# Optionally add your username
# Uncomment and replace YOUR_USERNAME with your actual username
# nmcli connection modify "$VPN_NAME" vpn.user-name YOUR_USERNAME

echo "VPN connection configured successfully."
echo "You can now use the GNOME network toggle to connect to the VPN."
echo ""
echo "To connect via command line:"
echo "nmcli connection up $VPN_NAME"
echo ""
echo "To see connection details:"
echo "nmcli connection show $VPN_NAME"