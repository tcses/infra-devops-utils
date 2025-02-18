echo -e "\n=== Thermal Information ==="
echo "CPU Temperature: $(sensors | grep 'Package id 0:' | cut -d '+' -f2 | cut -d ' ' -f1)"
echo "Fan Speed: $(cat /proc/acpi/ibm/fan | grep 'speed:' | awk '{print $2}') RPM"

echo -e "\n=== Battery Health ==="
echo "Battery Cycle Count: $(cat /sys/class/power_supply/BAT0/cycle_count)"
echo "Battery Capacity: $(cat /sys/class/power_supply/BAT0/capacity)%"
echo "Design Capacity: $(cat /sys/class/power_supply/BAT0/energy_full_design)mWh"
echo "Current Capacity: $(cat /sys/class/power_supply/BAT0/energy_full)mWh"