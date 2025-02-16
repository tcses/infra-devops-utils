# Create the directory if it doesn't exist
sudo mkdir -p /etc/tlp.d

# Create your custom config
sudo tee /etc/tlp.d/99-custom-settings.conf << 'EOF'
# ThinkPad P16s Gen 2 with Ryzen 7 PRO 7840U customizations

# CPU Settings
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Platform Profile
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=balanced

# Energy Performance Preference
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# AMD GPU settings for Radeon 780M
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery

# Battery charge thresholds
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF

# Restart TLP to apply settings
sudo tlp start

# ########### Create shortcut to configure modes in userland ###########

# Create a directory for your scripts
mkdir -p ~/.local/bin

# Create a script to switch to performance mode
tee ~/.local/bin/tlp-performance << 'EOF'
#!/bin/bash
sudo tlp ac
echo "Switched to performance mode"
EOF

# Create a script to switch to battery-saving mode
tee ~/.local/bin/tlp-battery << 'EOF'
#!/bin/bash
sudo tlp bat
echo "Switched to battery-saving mode"
EOF

# Create a script to check current TLP status
tee ~/.local/bin/tlp-status << 'EOF'
#!/bin/bash
sudo tlp-stat -s
EOF

# Make the scripts executable
chmod +x ~/.local/bin/tlp-performance
chmod +x ~/.local/bin/tlp-battery
chmod +x ~/.local/bin/tlp-status

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

source ~/.bashrc