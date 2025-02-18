# Create the directory if it doesn't exist
sudo mkdir -p /etc/tlp.d

# Create your custom config
sudo tee /etc/tlp.d/99-custom-settings.conf << 'EOF'
# ThinkPad P16s Gen 2 AMD Ryzen Configuration

# CPU Settings
CPU_SCALING_GOVERNOR_ON_AC=schedutil
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Platform Profiles
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power

# Performance Scaling
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=80
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=50

# Energy Performance Preference
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# AMD-specific settings
RADEON_DPM_STATE_ON_AC=balanced
RADEON_DPM_STATE_ON_BAT=battery
RADEON_POWER_PROFILE_ON_AC=balanced
RADEON_POWER_PROFILE_ON_BAT=low

# Battery charge thresholds
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF

# Restart TLP to apply settings
sudo tlp start

# Create scripts directory
mkdir -p ~/.local/bin

# Create a script to switch to performance mode
tee ~/.local/bin/tlp-performance << 'EOF'
#!/bin/bash
echo "Switching to performance mode..."

# AMD-specific performance settings
sudo cpupower frequency-set -g performance
echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sudo sed -i 's/^RADEON_DPM_STATE_ON_AC=.*/RADEON_DPM_STATE_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^RADEON_POWER_PROFILE_ON_AC=.*/RADEON_POWER_PROFILE_ON_AC=high/' /etc/tlp.d/99-custom-settings.conf

# Common TLP performance settings
sudo sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^CPU_MAX_PERF_ON_AC=.*/CPU_MAX_PERF_ON_AC=100/' /etc/tlp.d/99-custom-settings.conf

sudo tlp ac
echo "Performance mode activated"
EOF

# Create a script to switch to balanced mode
tee ~/.local/bin/tlp-balanced << 'EOF'
#!/bin/bash
echo "Switching to balanced mode..."

# AMD-specific balanced settings
sudo cpupower frequency-set -g schedutil
echo "schedutil" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sudo sed -i 's/^RADEON_DPM_STATE_ON_AC=.*/RADEON_DPM_STATE_ON_AC=balanced/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^RADEON_POWER_PROFILE_ON_AC=.*/RADEON_POWER_PROFILE_ON_AC=balanced/' /etc/tlp.d/99-custom-settings.conf

# Common TLP balanced settings
sudo sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=balanced/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^CPU_MAX_PERF_ON_AC=.*/CPU_MAX_PERF_ON_AC=80/' /etc/tlp.d/99-custom-settings.conf

sudo tlp ac
echo "Balanced mode activated"
EOF

# Create a script to switch to battery mode
tee ~/.local/bin/tlp-battery << 'EOF'
#!/bin/bash
echo "Switching to battery mode..."

# AMD-specific power-saving settings
sudo cpupower frequency-set -g powersave
echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sudo sed -i 's/^RADEON_DPM_STATE_ON_AC=.*/RADEON_DPM_STATE_ON_AC=battery/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^RADEON_POWER_PROFILE_ON_AC=.*/RADEON_POWER_PROFILE_ON_AC=low/' /etc/tlp.d/99-custom-settings.conf

sudo tlp bat
echo "Battery mode activated"
EOF

# Create an enhanced status script
tee ~/.local/bin/tlp-status << 'EOF'
#!/bin/bash
echo "=== TLP Status ==="
sudo tlp-stat -s

echo -e "\n=== CPU Information ==="
echo "CPU Type: AMD Ryzen"
echo "Current governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "Current frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) KHz"
echo "Max frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
echo "Min frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) KHz"

echo -e "\n=== Power Profiles ==="
echo "AC Profile: $(grep PLATFORM_PROFILE_ON_AC /etc/tlp.d/99-custom-settings.conf)"
echo "Battery Profile: $(grep PLATFORM_PROFILE_ON_BAT /etc/tlp.d/99-custom-settings.conf)"

echo -e "\n=== Current Settings ==="
echo "Power Source: $(cat /sys/class/power_supply/AC/online | grep -q "1" && echo "AC" || echo "Battery")"
echo "Performance Mode: $(grep "CPU_MAX_PERF_ON_AC" /etc/tlp.d/99-custom-settings.conf)"

echo -e "\n=== AMD-specific Settings ==="
echo "DPM State: $(grep RADEON_DPM_STATE_ON_AC /etc/tlp.d/99-custom-settings.conf)"
echo "Power Profile: $(grep RADEON_POWER_PROFILE_ON_AC /etc/tlp.d/99-custom-settings.conf)"
EOF

# Make the scripts executable
chmod +x ~/.local/bin/tlp-performance
chmod +x ~/.local/bin/tlp-balanced
chmod +x ~/.local/bin/tlp-battery
chmod +x ~/.local/bin/tlp-status

# Add scripts to PATH if not already there
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

source ~/.bashrc