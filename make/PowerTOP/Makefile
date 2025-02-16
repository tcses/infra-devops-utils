.PHONY: all install clean powertop tlp disable-lte usb pci disk systemd

all: install

install: powertop tlp disable-lte usb pci disk systemd
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
	@echo auto | sudo tee /sys/block/sda/device/power/control

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
	sudo update-initramfs -u