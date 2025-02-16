# Power management Makefile for Intel and AMD systems
# 'make' or 'make all' will run all power management configurations

.PHONY: all powertop tlp cpu-specific disable-lte usb pci disk systemd clean

all: powertop tlp cpu-specific disable-lte usb pci disk systemd
	@echo "All power management settings have been applied"

powertop:
	@echo "Configuring PowerTOP settings..."
	@echo 1500 | sudo tee /proc/sys/vm/dirty_writeback_centisecs
	@echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog
	sudo powertop --auto-tune

tlp:
	@echo "Installing and configuring TLP..."
	sudo apt install -y tlp
	sudo systemctl enable tlp
	sudo systemctl start tlp
	# Configure CPU-specific TLP settings
	@if [ -f /proc/cpuinfo ] && grep -qi "intel" /proc/cpuinfo; then \
		echo "Configuring Intel-specific TLP settings..."; \
		sudo sed -i '/CPU_SCALING_GOVERNOR_ON_AC/c\CPU_SCALING_GOVERNOR_ON_AC=performance' /etc/tlp.conf; \
		sudo sed -i '/CPU_SCALING_GOVERNOR_ON_BAT/c\CPU_SCALING_GOVERNOR_ON_BAT=powersave' /etc/tlp.conf; \
		sudo sed -i '/CPU_HWP_ON_AC/c\CPU_HWP_ON_AC=performance' /etc/tlp.conf; \
	elif [ -f /proc/cpuinfo ] && grep -qi "amd" /proc/cpuinfo; then \
		echo "Configuring AMD-specific TLP settings..."; \
		sudo sed -i '/CPU_SCALING_GOVERNOR_ON_AC/c\CPU_SCALING_GOVERNOR_ON_AC=performance' /etc/tlp.conf; \
		sudo sed -i '/CPU_SCALING_GOVERNOR_ON_BAT/c\CPU_SCALING_GOVERNOR_ON_BAT=powersave' /etc/tlp.conf; \
		sudo sed -i '/PLATFORM_PROFILE_ON_AC/c\PLATFORM_PROFILE_ON_AC=performance' /etc/tlp.conf; \
		sudo sed -i '/PLATFORM_PROFILE_ON_BAT/c\PLATFORM_PROFILE_ON_BAT=low-power' /etc/tlp.conf; \
		sudo sed -i '/CPU_ENERGY_PERF_POLICY_ON_AC/c\CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance' /etc/tlp.conf; \
		sudo sed -i '/CPU_ENERGY_PERF_POLICY_ON_BAT/c\CPU_ENERGY_PERF_POLICY_ON_BAT=power' /etc/tlp.conf; \
	fi

cpu-specific:
	@echo "Applying CPU-specific optimizations..."
	@if [ -f /proc/cpuinfo ] && grep -qi "intel" /proc/cpuinfo; then \
		echo "Detected Intel CPU, applying Intel-specific settings..."; \
		if [ -d /sys/devices/system/cpu/intel_pstate ]; then \
			echo "Configuring intel_pstate..."; \
			echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo; \
		fi; \
	elif [ -f /proc/cpuinfo ] && grep -qi "amd" /proc/cpuinfo; then \
		echo "Detected AMD CPU, applying AMD-specific settings..."; \
		if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then \
			echo "Configuring AMD frequency scaling..."; \
			for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do \
				[ -f "$$cpu/scaling_min_freq" ] && echo 400000 | sudo tee "$$cpu/scaling_min_freq"; \
				[ -f "$$cpu/scaling_max_freq" ] && echo 5132000 | sudo tee "$$cpu/scaling_max_freq"; \
				[ -f "$$cpu/energy_performance_preference" ] && echo "balance_performance" | sudo tee "$$cpu/energy_performance_preference"; \
			done; \
		fi; \
		if [ -e /sys/devices/system/cpu/amd_pstate/status ]; then \
			echo "active" | sudo tee /sys/devices/system/cpu/amd_pstate/status; \
		fi; \
	fi

disable-lte:
	@echo "Disabling LTE module..."
	@echo "blacklist cdc_mbim" | sudo tee /etc/modprobe.d/disable-lte.conf
	sudo update-initramfs -u

usb:
	@echo "Configuring USB power management..."
	@for device in /sys/bus/usb/devices/*; do \
		[ -e "$$device/power/control" ] && echo auto | sudo tee "$$device/power/control"; \
	done

pci:
	@echo "Configuring PCI power management..."
	@for device in /sys/bus/pci/devices/*; do \
		[ -e "$$device/power/control" ] && echo auto | sudo tee "$$device/power/control"; \
	done

disk:
	@echo "Configuring disk power management..."
	@for disk in /sys/block/*/device/power/control; do \
		[ -e "$$disk" ] && echo auto | sudo tee "$$disk"; \
	done

systemd:
	@echo "Creating and enabling PowerTOP systemd service..."
	@sudo cp powertop-tuning.service /etc/systemd/system/
	sudo systemctl enable powertop-tuning.service
	sudo systemctl start powertop-tuning.service

clean:
	@echo "Performing complete cleanup of all power management settings..."
	
	# Stop and remove services
	@echo "Removing services..."
	sudo systemctl stop powertop-tuning.service || true
	sudo systemctl disable powertop-tuning.service || true
	sudo rm -f /etc/systemd/system/powertop-tuning.service
	
	# Remove TLP completely
	@echo "Removing TLP..."
	sudo systemctl stop tlp || true
	sudo systemctl disable tlp || true
	sudo apt purge -y tlp tlp-rdw || true
	sudo apt autoremove -y
	
	# Reset PowerTOP settings
	@echo "Resetting PowerTOP settings..."
	@echo 500 | sudo tee /proc/sys/vm/dirty_writeback_centisecs || true
	@echo 1 | sudo tee /proc/sys/kernel/nmi_watchdog || true
	
	# Reset USB power management
	@echo "Resetting USB power management..."
	@for device in /sys/bus/usb/devices/*; do \
		[ -e "$$device/power/control" ] && echo on | sudo tee "$$device/power/control" || true; \
	done
	
	# Reset PCI power management
	@echo "Resetting PCI power management..."
	@for device in /sys/bus/pci/devices/*; do \
		[ -e "$$device/power/control" ] && echo on | sudo tee "$$device/power/control" || true; \
	done
	
	# Reset disk power management
	@echo "Resetting disk power management..."
	@for disk in /sys/block/*/device/power/control; do \
		[ -e "$$disk" ] && echo on | sudo tee "$$disk" || true; \
	done
	
	# Reset CPU-specific settings
	@echo "Resetting CPU-specific settings..."
	@if [ -f /proc/cpuinfo ] && grep -qi "intel" /proc/cpuinfo; then \
		if [ -d /sys/devices/system/cpu/intel_pstate ]; then \
			echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo || true; \
		fi; \
	elif [ -f /proc/cpuinfo ] && grep -qi "amd" /proc/cpuinfo; then \
		if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then \
			for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do \
				[ -f "$$cpu/scaling_min_freq" ] && echo 400000 | sudo tee "$$cpu/scaling_min_freq" || true; \
				[ -f "$$cpu/scaling_max_freq" ] && echo 5132000 | sudo tee "$$cpu/scaling_max_freq" || true; \
				[ -f "$$cpu/energy_performance_preference" ] && echo "default" | sudo tee "$$cpu/energy_performance_preference" || true; \
			done; \
		fi; \
		if [ -e /sys/devices/system/cpu/amd_pstate/status ]; then \
			echo "passive" | sudo tee /sys/devices/system/cpu/amd_pstate/status || true; \
		fi; \
	fi
	
	# Remove configuration files
	@echo "Removing configuration files..."
	sudo rm -f /etc/modprobe.d/disable-lte.conf
	sudo rm -f /etc/tlp.conf.bak
	sudo rm -f /etc/tlp.d/*.conf
	
	# Clean package manager
	@echo "Cleaning package manager..."
	sudo apt clean
	sudo apt autoremove -y
	
	# Update system
	@echo "Updating initramfs..."
	sudo update-initramfs -u
	
	@echo "Cleanup complete. You may want to reboot your system for all changes to take effect."