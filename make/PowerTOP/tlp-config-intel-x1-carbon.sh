#!/bin/bash

echo "Installing and configuring ThinkPad X1 Carbon 6th Gen power management..."

# Install required packages
sudo apt-get update
sudo apt-get install -y git python3-dev libdbus-glib-1-dev libgirepository1.0-dev libcairo2-dev tlp tlp-rdw msr-tools

# Install throttled
git clone https://github.com/erpalma/throttled.git
cd throttled
sudo ./install.sh

# Configure throttled
sudo tee /etc/throttled.conf << EOF
[GENERAL]
# Enable or disable the script execution
Enabled: True
# SYSFS path for checking if the system is running on AC power
Sysfs_Power_Path: /sys/class/power_supply/AC/online

[BATTERY]
# Update the registers every this many seconds
Update_Rate_s: 30
# Max package power for time window #1
PL1_Tdp_W: 29
# Max package power for time window #2
PL2_Tdp_W: 44
# Max temperature before throttling
Trip_Temp_C: 85
# Set HWP energy performance hints to 'balance_power' on BAT
HWP_Mode: balance_power
# Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
cTDP: 0

[AC]
# Update the registers every this many seconds
Update_Rate_s: 5
# Max package power for time window #1
PL1_Tdp_W: 44
# Max package power for time window #2
PL2_Tdp_W: 44
# Max temperature before throttling
Trip_Temp_C: 95
# Set HWP energy performance hints to 'performance' on AC
HWP_Mode: performance
# Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
cTDP: 0

[UNDERVOLT]
# CPU core voltage offset (mV)
CORE: -100
# Integrated GPU voltage offset (mV)
GPU: -85
# CPU cache voltage offset (mV)
CACHE: -100
# System Agent voltage offset (mV)
UNCORE: -85
# Analog I/O voltage offset (mV)
ANALOGIO: 0
EOF

# Create TLP configuration
sudo mkdir -p /etc/tlp.d

sudo tee /etc/tlp.d/99-custom-settings.conf << 'EOF'
# ThinkPad X1 Carbon 6th Gen Intel i7 Configuration

# CPU Settings
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Platform Profiles
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=balanced

# CPU Frequencies (i7-8550U: 400MHz - 4000MHz)
CPU_SCALING_MIN_FREQ_ON_AC=400000
CPU_SCALING_MAX_FREQ_ON_AC=4000000
CPU_SCALING_MIN_FREQ_ON_BAT=400000
CPU_SCALING_MAX_FREQ_ON_BAT=3200000

# Hardware Power Management
CPU_HWP_ON_AC=balance_performance
CPU_HWP_ON_BAT=balance_power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1

# Energy Performance Preference
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# Intel GPU Settings
INTEL_GPU_MIN_FREQ_ON_AC=300
INTEL_GPU_MAX_FREQ_ON_AC=1150
INTEL_GPU_MIN_FREQ_ON_BAT=300
INTEL_GPU_MAX_FREQ_ON_BAT=1150
INTEL_GPU_BOOST_FREQ_ON_AC=1150
INTEL_GPU_BOOST_FREQ_ON_BAT=1150

# Battery charge thresholds
START_CHARGE_THRESH_BAT0=60
STOP_CHARGE_THRESH_BAT0=80
EOF

# Create scripts directory
sudo mkdir -p /usr/local/bin

# Create performance mode script
sudo tee /usr/local/bin/tlp-performance << 'EOF'
#!/bin/bash
echo "Switching to performance mode..."

# Set CPU frequency limits
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo 400000 | sudo tee $cpu/cpufreq/scaling_min_freq
    echo 4000000 | sudo tee $cpu/cpufreq/scaling_max_freq
done

# Enable Turbo Boost
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Update TLP settings
sudo sed -i 's/^CPU_HWP_ON_AC=.*/CPU_HWP_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf

sudo tlp ac
echo "Performance mode activated"

# Show current settings
echo -e "\nCurrent settings:"
echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "Min Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) KHz"
echo "Max Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
echo "Current Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) KHz"
EOF

# Create balanced mode script
sudo tee /usr/local/bin/tlp-balanced << 'EOF'
#!/bin/bash
echo "Switching to balanced mode..."

# Set CPU frequency limits
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo 400000 | sudo tee $cpu/cpufreq/scaling_min_freq
    echo 3400000 | sudo tee $cpu/cpufreq/scaling_max_freq
done

# Enable Turbo Boost
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Update TLP settings
sudo sed -i 's/^CPU_HWP_ON_AC=.*/CPU_HWP_ON_AC=balance_performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=balanced/' /etc/tlp.d/99-custom-settings.conf

sudo tlp ac
echo "Balanced mode activated"

# Show current settings
echo -e "\nCurrent settings:"
echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "Min Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) KHz"
echo "Max Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
echo "Current Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) KHz"
EOF

# Create battery mode script
sudo tee /usr/local/bin/tlp-battery << 'EOF'
#!/bin/bash
echo "Switching to battery mode..."

# Set CPU frequency limits
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo 400000 | sudo tee $cpu/cpufreq/scaling_min_freq
    echo 2800000 | sudo tee $cpu/cpufreq/scaling_max_freq
done

# Enable Turbo Boost but let TLP manage it
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Update TLP settings
sudo sed -i 's/^CPU_HWP_ON_BAT=.*/CPU_HWP_ON_BAT=balance_power/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power/' /etc/tlp.d/99-custom-settings.conf
sudo sed -i 's/^PLATFORM_PROFILE_ON_BAT=.*/PLATFORM_PROFILE_ON_BAT=balanced/' /etc/tlp.d/99-custom-settings.conf

sudo tlp bat
echo "Battery mode activated"

# Show current settings
echo -e "\nCurrent settings:"
echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "Min Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) KHz"
echo "Max Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
echo "Current Freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) KHz"
EOF

# Create status script
sudo tee /usr/local/bin/tlp-status << 'EOF'
#!/bin/bash
echo "=== TLP Status ==="
sudo tlp-stat -s

echo -e "\n=== CPU Information ==="
echo "CPU Type: Intel i7-8550U"
echo "Current governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "Current frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) KHz"
echo "Max frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
echo "Min frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) KHz"
echo "Turbo Boost: $([[ $(cat /sys/devices/system/cpu/intel_pstate/no_turbo) == 0 ]] && echo "Enabled" || echo "Disabled")"

echo -e "\n=== Throttling Status ==="
sudo rdmsr -f 29:24 -d 0x1a2

echo -e "\n=== Power Profiles ==="
echo "AC Profile: $(grep PLATFORM_PROFILE_ON_AC /etc/tlp.d/99-custom-settings.conf)"
echo "Battery Profile: $(grep PLATFORM_PROFILE_ON_BAT /etc/tlp.d/99-custom-settings.conf)"

echo -e "\n=== Current Settings ==="
echo "Power Source: $(cat /sys/class/power_supply/AC/online | grep -q "1" && echo "AC" || echo "Battery")"

echo -e "\n=== Thermal Information ==="
echo "CPU Temperature: $(sensors | grep 'Package id 0:' | cut -d '+' -f2 | cut -d ' ' -f1)"

echo -e "\n=== Battery Health ==="
echo "Battery Cycle Count: $(cat /sys/class/power_supply/BAT0/cycle_count)"
echo "Battery Capacity: $(cat /sys/class/power_supply/BAT0/capacity)%"
echo "Design Capacity: $(cat /sys/class/power_supply/BAT0/energy_full_design)mWh"
echo "Current Capacity: $(cat /sys/class/power_supply/BAT0/energy_full)mWh"
EOF

# Make scripts executable
sudo chmod +x /usr/local/bin/tlp-performance
sudo chmod +x /usr/local/bin/tlp-balanced
sudo chmod +x /usr/local/bin/tlp-battery
sudo chmod +x /usr/local/bin/tlp-status

# Enable and start services
sudo systemctl enable --now lenovo_fix.service
sudo tlp start

echo "Installation complete. You can now use:"
echo "sudo tlp-performance - for maximum performance (up to 4.0GHz)"
echo "sudo tlp-balanced   - for balanced operation (up to 3.4GHz)"
echo "sudo tlp-battery    - for optimized battery life (up to 2.8GHz)"
echo "tlp-status         - to check current settings"