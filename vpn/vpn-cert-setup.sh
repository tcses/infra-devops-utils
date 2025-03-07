#!/bin/bash

# Script to download and set up certificates for openconnect VPN
# Usage: ./script.sh vpn.example.com

set -e  # Exit on any error

# Check if hostname is provided
if [ $# -eq 0 ]; then
  echo "Error: VPN hostname is required"
  echo "Usage: $0 vpn.example.com"
  exit 1
fi

VPN_HOST="$1"
echo "Setting up certificates for $VPN_HOST..."

# Create directory for certificates if it doesn't exist
CERT_DIR="$HOME/.vpn-certs/$VPN_HOST"
mkdir -p "$CERT_DIR"

# Try to retrieve all certificates in the chain
echo "Downloading certificate chain from $VPN_HOST..."
CERT_TEMP="$CERT_DIR/cert_chain.pem"
echo | openssl s_client -connect "$VPN_HOST:443" -showcerts -servername "$VPN_HOST" 2>/dev/null > "$CERT_TEMP"

if [ ! -s "$CERT_TEMP" ]; then
  echo "Error: Failed to download certificates"
  exit 1
fi

# Extract all certificates from the chain
echo "Extracting certificates from chain..."
awk 'BEGIN {c=0} /BEGIN CERT/{c++} { print > "'$CERT_DIR'/cert." c ".pem"}' < "$CERT_TEMP"

# Get the number of certificates extracted
CERT_COUNT=$(ls "$CERT_DIR"/cert.*.pem | wc -l)
echo "Found $CERT_COUNT certificates in the chain"

# Import all certificates to the trusted store
for CERT_FILE in "$CERT_DIR"/cert.*.pem; do
  CERT_NAME=$(basename "$CERT_FILE" .pem)
  echo "Processing certificate: $CERT_NAME"
  
  # Get certificate details
  SUBJECT=$(openssl x509 -in "$CERT_FILE" -noout -subject | sed 's/^subject=//')
  ISSUER=$(openssl x509 -in "$CERT_FILE" -noout -issuer | sed 's/^issuer=//')
  FINGERPRINT_SHA1=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha1 | cut -d'=' -f2)
  FINGERPRINT_SHA256=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha256 | cut -d'=' -f2)
  
  echo "  Subject: $SUBJECT"
  echo "  Issuer: $ISSUER"
  echo "  SHA1 Fingerprint: $FINGERPRINT_SHA1"
  echo "  SHA256 Fingerprint: $FINGERPRINT_SHA256"
  
  # Save fingerprints for later use
  echo "$FINGERPRINT_SHA1" >> "$CERT_DIR/fingerprints_sha1.txt"
  echo "$FINGERPRINT_SHA256" >> "$CERT_DIR/fingerprints_sha256.txt"
  
  # Copy to system's CA store
  SAFE_NAME=$(echo "$VPN_HOST-$CERT_NAME" | tr -c '[:alnum:]' '_')
  sudo cp "$CERT_FILE" "/usr/local/share/ca-certificates/$SAFE_NAME.crt"
done

# Update CA certificates
echo "Updating system CA certificates..."
sudo update-ca-certificates

# Combine all certificates into one file
cat "$CERT_DIR"/cert.*.pem > "$CERT_DIR/all_certs.pem"

# Create a configuration file with multiple certificate options
echo "Creating OpenConnect configuration..."
CONFIG_FILE="$CERT_DIR/openconnect.conf"
cat > "$CONFIG_FILE" << EOF
# OpenConnect configuration for $VPN_HOST
server=$VPN_HOST
cafile=$CERT_DIR/all_certs.pem
EOF

# Add all fingerprints as options
echo "# SHA1 Fingerprints" >> "$CONFIG_FILE"
while read -r fp; do
  fp_clean=$(echo "$fp" | tr -d ':')
  echo "# servercert=sha1:$fp_clean" >> "$CONFIG_FILE"
done < "$CERT_DIR/fingerprints_sha1.txt"

echo "# SHA256 Fingerprints" >> "$CONFIG_FILE"
while read -r fp; do
  fp_clean=$(echo "$fp" | tr -d ':')
  echo "# servercert=pin-sha256:$fp_clean" >> "$CONFIG_FILE"
done < "$CERT_DIR/fingerprints_sha256.txt"

# Create connection scripts for different methods
echo "Creating connection scripts..."

# Regular connection
CONNECT_SCRIPT="$CERT_DIR/connect.sh"
cat > "$CONNECT_SCRIPT" << EOF
#!/bin/bash
echo "Connecting to $VPN_HOST using CA certificates..."
sudo openconnect --cafile=$CERT_DIR/all_certs.pem $VPN_HOST \$@
EOF
chmod +x "$CONNECT_SCRIPT"

# Direct fingerprint connection (SHA1)
CONNECT_SHA1="$CERT_DIR/connect_sha1.sh"
cat > "$CONNECT_SHA1" << EOF
#!/bin/bash
echo "Connecting to $VPN_HOST using SHA1 fingerprint..."
FINGERPRINT=\$(head -1 "$CERT_DIR/fingerprints_sha1.txt" | tr -d ':')
sudo openconnect --servercert=sha1:\$FINGERPRINT $VPN_HOST \$@
EOF
chmod +x "$CONNECT_SHA1"

# Direct fingerprint connection (SHA256)
CONNECT_SHA256="$CERT_DIR/connect_sha256.sh"
cat > "$CONNECT_SHA256" << EOF
#!/bin/bash
echo "Connecting to $VPN_HOST using SHA256 fingerprint..."
FINGERPRINT=\$(head -1 "$CERT_DIR/fingerprints_sha256.txt" | tr -d ':')
sudo openconnect --servercert=pin-sha256:\$FINGERPRINT $VPN_HOST \$@
EOF
chmod +x "$CONNECT_SHA256"

# Create a debug script
DEBUG_SCRIPT="$CERT_DIR/debug_connect.sh"
cat > "$DEBUG_SCRIPT" << EOF
#!/bin/bash
echo "Running OpenConnect in debug mode for $VPN_HOST..."
sudo openconnect -v --cafile=$CERT_DIR/all_certs.pem $VPN_HOST \$@
EOF
chmod +x "$DEBUG_SCRIPT"

# Create NetworkManager configuration if NetworkManager is present
if command -v nmcli &> /dev/null; then
  echo "Setting up NetworkManager configuration..."
  
  SAFE_VPN_NAME=$(echo "vpn-$VPN_HOST" | tr -c '[:alnum:]' '-')
  
  # Check if connection already exists
  if nmcli connection show | grep -q "$SAFE_VPN_NAME"; then
    nmcli connection delete "$SAFE_VPN_NAME"
  fi
  
  # Add new VPN connection
  nmcli connection add \
    type vpn \
    vpn-type openconnect \
    con-name "$SAFE_VPN_NAME" \
    ifname "*" \
    vpn.data "gateway=$VPN_HOST,cacert=$CERT_DIR/all_certs.pem,certsigs-flags=0"
  
  echo "NetworkManager VPN connection '$SAFE_VPN_NAME' created."
fi

echo ""
echo "==================================================="
echo "Setup complete! Here are your connection options:"
echo "==================================================="
echo "1. Using CA certificates:"
echo "   $CONNECT_SCRIPT"
echo ""
echo "2. Using SHA1 fingerprint:"
echo "   $CONNECT_SHA1"
echo ""
echo "3. Using SHA256 fingerprint:"
echo "   $CONNECT_SHA256"
echo ""
echo "4. Debug mode with verbose output:"
echo "   $DEBUG_SCRIPT"
echo ""

if command -v nmcli &> /dev/null; then
  echo "5. NetworkManager:"
  echo "   nmcli connection up $SAFE_VPN_NAME"
  echo "   Or use the NetworkManager GUI"
  echo ""
fi

# Display the SHA256 fingerprint from the error message if any
SHA256_ERROR=$(grep -o "pin-sha256:[A-Za-z0-9+/=]*" "$CERT_TEMP" 2>/dev/null || true)
if [ -n "$SHA256_ERROR" ]; then
  echo "Found SHA256 fingerprint in server response: $SHA256_ERROR"
  echo "Try connecting with:"
  echo "sudo openconnect --servercert=$SHA256_ERROR $VPN_HOST"
  echo ""
fi

echo "If you're still having issues, try the following command:"
echo "sudo openconnect -v --no-cert-check $VPN_HOST"
echo "This will allow you to connect insecurely for testing purposes only."
echo ""
echo "Note: If you're connecting to vpn02.tcsedsystem.edu but ran this script"
echo "with a different hostname, run the script again with the exact hostname."