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
			for policy in /sys/devices/system/cpu/cpufreq/policy*; do \
				echo "schedutil" | sudo tee $$policy/scaling_governor; \
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
	@echo "Reverting power management settings..."
	sudo systemctl stop powertop-tuning.service
	sudo systemctl disable powertop-tuning.service
	sudo rm -f /etc/systemd/system/powertop-tuning.service
	sudo rm -f /etc/modprobe.d/disable-lte.conf
	sudo systemctl stop tlp
	sudo systemctl disable tlp
	sudo apt remove -y tlp
	@if [ -f /proc/cpuinfo ] && grep -qi "intel" /proc/cpuinfo; then \
		if [ -d /sys/devices/system/cpu/intel_pstate ]; then \
			echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo; \
		fi; \
	elif [ -f /proc/cpuinfo ] && grep -qi "amd" /proc/cpuinfo; then \
		if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then \
			for policy in /sys/devices/system/cpu/cpufreq/policy*; do \
				echo "performance" | sudo tee $$policy/scaling_governor; \
			done; \
		fi; \
		if [ -e /sys/devices/system/cpu/amd_pstate/status ]; then \
			echo "passive" | sudo tee /sys/devices/system/cpu/amd_pstate/status; \
		fi; \
	fi
	sudo update-initramfs -u