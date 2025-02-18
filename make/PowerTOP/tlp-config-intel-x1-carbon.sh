# Create the directory if it doesn't exist
sudo mkdir -p /etc/tlp.d

# Create your custom config
sudo tee /etc/tlp.d/99-custom-settings.conf << 'EOF'
# ThinkPad X1 Carbon 6th Gen Intel i7 Configuration

# CPU Settings
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Platform Profiles
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Intel CPU Settings
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=60

# Hardware Power Management
CPU_HWP_ON_AC=performance
CPU_HWP_ON_BAT=power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Energy Performance Preference
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# Intel GPU Settings
INTEL_GPU_MIN_FREQ_ON_AC=300
INTEL_GPU_MAX_FREQ_ON_AC=1150
INTEL_GPU_MIN_FREQ_ON_BAT=300
INTEL_GPU_MAX_FREQ_ON_BAT=900
INTEL_GPU_BOOST_FREQ_ON_AC=1150
INTEL_GPU_BOOST_FREQ_ON_BAT=900

# Battery charge thresholds
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF

# Restart TLP to apply settings
sudo tlp start

# Create scripts directory
sudo mkdir -p /usr/local/bin

# Create a script to switch to performance mode
sudo tee /usr/local/bin/tlp-performance << 'EOF'
#!/bin/bash
echo "Switching to performance mode..."

# Enable Turbo Boost and set Intel P-state parameters
echo 0 | tee /sys/devices/system/cpu/intel_pstate/no_turbo
echo 100 | tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo 25 | tee /sys/devices/system/cpu/intel_pstate/min_perf_pct

# Set scaling frequencies
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo 4000000 > $cpu/cpufreq/scaling_max_freq
    echo 400000 > $cpu/cpufreq/scaling_min_freq
done

# Intel-specific performance settings
cpupower frequency-set -g performance
echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sed -i 's/^CPU_HWP_ON_AC=.*/CPU_HWP_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' /etc/tlp.d/99-custom-settings.conf

# Common TLP performance settings
sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=performance/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_MAX_PERF_ON_AC=.*/CPU_MAX_PERF_ON_AC=100/' /etc/tlp.d/99-custom-settings.conf

tlp ac
echo "Performance mode activated with Turbo Boost enabled"

# Verify settings
echo -e "\nVerifying settings:"
echo "Turbo Boost: $([[ $(cat /sys/devices/system/cpu/intel_pstate/no_turbo) == 0 ]] && echo "Enabled" || echo "Disabled")"
echo "Max Performance: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)%"
echo "Max Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
EOF

# Create a script to switch to balanced mode
sudo tee /usr/local/bin/tlp-balanced << 'EOF'
#!/bin/bash
echo "Switching to balanced mode..."

# Enable Turbo Boost with limits
echo 0 | tee /sys/devices/system/cpu/intel_pstate/no_turbo
echo 80 | tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo 20 | tee /sys/devices/system/cpu/intel_pstate/min_perf_pct

# Set scaling frequencies
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo 3000000 > $cpu/cpufreq/scaling_max_freq
    echo 400000 > $cpu/cpufreq/scaling_min_freq
done

# Intel-specific balanced settings
cpupower frequency-set -g performance
echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sed -i 's/^CPU_HWP_ON_AC=.*/CPU_HWP_ON_AC=balance_performance/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' /etc/tlp.d/99-custom-settings.conf

# Common TLP balanced settings
sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=balanced/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_MAX_PERF_ON_AC=.*/CPU_MAX_PERF_ON_AC=80/' /etc/tlp.d/99-custom-settings.conf

tlp ac
echo "Balanced mode activated with limited Turbo Boost"

# Verify settings
echo -e "\nVerifying settings:"
echo "Turbo Boost: $([[ $(cat /sys/devices/system/cpu/intel_pstate/no_turbo) == 0 ]] && echo "Enabled" || echo "Disabled")"
echo "Max Performance: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)%"
echo "Max Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
EOF

# Create a script to switch to battery mode
sudo tee /usr/local/bin/tlp-battery << 'EOF'
#!/bin/bash
echo "Switching to battery mode..."

# Disable Turbo Boost for maximum battery life
echo 1 | tee /sys/devices/system/cpu/intel_pstate/no_turbo
echo 60 | tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo 20 | tee /sys/devices/system/cpu/intel_pstate/min_perf_pct

# Set scaling frequencies
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    echo 1800000 > $cpu/cpufreq/scaling_max_freq
    echo 400000 > $cpu/cpufreq/scaling_min_freq
done

# Intel-specific power-saving settings
cpupower frequency-set -g powersave
echo "powersave" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sed -i 's/^CPU_HWP_ON_AC=.*/CPU_HWP_ON_AC=power/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=power/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=0/' /etc/tlp.d/99-custom-settings.conf

# Common TLP battery settings
sed -i 's/^PLATFORM_PROFILE_ON_AC=.*/PLATFORM_PROFILE_ON_AC=low-power/' /etc/tlp.d/99-custom-settings.conf
sed -i 's/^CPU_MAX_PERF_ON_AC=.*/CPU_MAX_PERF_ON_AC=60/' /etc/tlp.d/99-custom-settings.conf

tlp bat
echo "Battery mode activated with Turbo Boost disabled"

# Verify settings
echo -e "\nVerifying settings:"
echo "Turbo Boost: $([[ $(cat /sys/devices/system/cpu/intel_pstate/no_turbo) == 0 ]] && echo "Enabled" || echo "Disabled")"
echo "Max Performance: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)%"
echo "Max Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) KHz"
EOF

# Create an enhanced status script
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
echo "Max Performance: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)%"

echo -e "\n=== Power Profiles ==="
echo "AC Profile: $(grep PLATFORM_PROFILE_ON_AC /etc/tlp.d/99-custom-settings.conf)"
echo "Battery Profile: $(grep PLATFORM_PROFILE_ON_BAT /etc/tlp.d/99-custom-settings.conf)"

echo -e "\n=== Current Settings ==="
echo "Power Source: $(cat /sys/class/power_supply/AC/online | grep -q "1" && echo "AC" || echo "Battery")"
echo "Performance Mode: $(grep "CPU_MAX_PERF_ON_AC" /etc/tlp.d/99-custom-settings.conf)"

echo -e "\n=== Intel-specific Settings ==="
echo "HWP Setting: $(grep CPU_HWP_ON_AC /etc/tlp.d/99-custom-settings.conf)"
echo "Energy Performance: $(grep CPU_ENERGY_PERF_POLICY_ON_AC /etc/tlp.d/99-custom-settings.conf)"
echo "GPU Frequencies: $(grep INTEL_GPU_MAX_FREQ_ON_AC /etc/tlp.d/99-custom-settings.conf)"

echo -e "\n=== Thermal Information ==="
echo "CPU Temperature: $(sensors | grep 'Package id 0:' | cut -d '+' -f2 | cut -d ' ' -f1)"
echo "Fan Speed: $(cat /proc/acpi/ibm/fan | grep 'speed:' | awk '{print $2}') RPM"

echo -e "\n=== Battery Health ==="
echo "Battery Cycle Count: $(cat /sys/class/power_supply/BAT0/cycle_count)"
echo "Battery Capacity: $(cat /sys/class/power_supply/BAT0/capacity)%"
echo "Design Capacity: $(cat /sys/class/power_supply/BAT0/energy_full_design)mWh"
echo "Current Capacity: $(cat /sys/class/power_supply/BAT0/energy_full)mWh"
EOF

# Make all scripts executable
sudo chmod +x /usr/local/bin/tlp-performance
sudo chmod +x /usr/local/bin/tlp-balanced
sudo chmod +x /usr/local/bin/tlp-battery
sudo chmod +x /usr/local/bin/tlp-status

echo "Installation complete. You can now use:"
echo "sudo tlp-performance - for maximum performance with Turbo Boost (up to 4.0GHz)"
echo "sudo tlp-balanced   - for daily use with limited Turbo (up to 3.0GHz)"
echo "sudo tlp-battery    - for maximum battery life (up to 1.8GHz, no Turbo)"
echo "tlp-status         - to check current settings"