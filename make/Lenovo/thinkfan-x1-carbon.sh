#!/bin/bash

echo "Installing and configuring thinkfan for ThinkPad X1 Carbon 6th Gen..."

# Install thinkfan and required modules
sudo apt-get update
sudo apt-get install -y thinkfan

# Enable thinkpad_acpi module with fan control
echo "options thinkpad_acpi fan_control=1" | sudo tee /etc/modprobe.d/thinkpad_acpi.conf

# Load the module immediately
sudo modprobe -r thinkpad_acpi
sudo modprobe thinkpad_acpi fan_control=1

# Backup existing config if it exists
if [ -f /etc/thinkfan.conf ]; then
    sudo cp /etc/thinkfan.conf /etc/thinkfan.conf.backup
    echo "Backed up original configuration to /etc/thinkfan.conf.backup"
fi

# Find the correct hwmon path
HWMON_PATH=$(find /sys/devices -type f -name "temp1_input" | grep coretemp | head -n1 | sed 's/temp1_input//')

# Create new thinkfan configuration
sudo tee /etc/thinkfan.conf << EOF
tp_fan /proc/acpi/ibm/fan
hwmon ${HWMON_PATH}temp1_input
hwmon ${HWMON_PATH}temp2_input
hwmon ${HWMON_PATH}temp3_input
hwmon ${HWMON_PATH}temp4_input

(0,     0,      45)
(1,     40,     50)
(2,     45,     55)
(3,     50,     60)
(4,     55,     65)
(5,     60,     70)
(7,     65,     75)
(7,     70,     85)
EOF

# Create systemd service override
sudo mkdir -p /etc/systemd/system/thinkfan.service.d/
sudo tee /etc/systemd/system/thinkfan.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/thinkfan -nq
EOF

# Ensure fan control is enabled
sudo chmod u+s /usr/sbin/thinkfan

# Reload systemd and restart thinkfan
sudo systemctl daemon-reload
sudo systemctl enable thinkfan
sudo systemctl restart thinkfan

# Create a status script
sudo tee /usr/local/bin/thinkfan-status << 'EOF'
#!/bin/bash

echo "=== ThinkFan Status ==="
if systemctl is-active --quiet thinkfan; then
    echo "ThinkFan Service: Running"
    echo "Service Status:"
    systemctl status thinkfan --no-pager
else
    echo "ThinkFan Service: Not Running"
    echo "Error Details:"
    systemctl status thinkfan --no-pager
fi

echo -e "\n=== Fan Speed ==="
cat /proc/acpi/ibm/fan

echo -e "\n=== CPU Temperatures ==="
sensors | grep "Core"

echo -e "\n=== ThinkPad Sensors ==="
cat /proc/acpi/ibm/thermal

echo -e "\n=== Fan Control Status ==="
echo "Fan Control Enabled: $(cat /proc/acpi/ibm/fan | grep "commands" | grep -q "level" && echo "Yes" || echo "No")"
EOF

# Make the status script executable
sudo chmod +x /usr/local/bin/thinkfan-status

echo "Installation complete. To check status, run: thinkfan-status"
echo -e "\nVerifying installation..."
sleep 2
thinkfan-status