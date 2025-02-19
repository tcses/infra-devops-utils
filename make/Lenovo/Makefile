.PHONY: all install deps clean

# Default target
all: install

# Check if running as root
check:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "This makefile needs to be run as root (sudo make ...)"; \
		exit 1; \
	fi

# Install system dependencies
deps: check
	apt update
	apt install -y git python3-dev python3-venv python3-pip python3-full \
		libdbus-glib-1-dev build-essential libcairo2-dev pkg-config \
		python3-cairo-dev libgirepository1.0-dev gir1.2-gtk-3.0 cmake

.PHONY: trackpoint-config trackpoint-test trackpoint-apply

trackpoint-config:
	@echo "Configuring TrackPoint settings..."
	@sudo mkdir -p /etc/udev/rules.d
	@echo 'SUBSYSTEM=="serio", DRIVER=="psmouse", ATTR{protocol}=="TPPS/2", ATTR{sensitivity}="200"' | sudo tee /etc/udev/rules.d/10-trackpoint.rules > /dev/null
	@sudo udevadm trigger
	@sudo udevadm control --reload-rules
	@make trackpoint-apply
	@make trackpoint-test

trackpoint-apply:
	@echo "Applying settings directly..."
	@sudo sh -c 'echo 200 > /sys/devices/pci0000:00/0000:00:1f.4/i2c-0/0-002c/rmi4-00/rmi4-00.fn03/serio3/sensitivity'

trackpoint-test:
	@echo "Current TrackPoint settings:"
	@echo "Sensitivity:" && cat /sys/devices/pci0000:00/0000:00:1f.4/i2c-0/0-002c/rmi4-00/rmi4-00.fn03/serio3/sensitivity
	@echo "\nVerifying udev rule:"
	@cat /etc/udev/rules.d/10-trackpoint.rules

help:
	@echo "Available targets:"
	@echo "  trackpoint-config  - Configure TrackPoint sensitivity"
	@echo "  trackpoint-apply  - Apply settings directly"
	@echo "  trackpoint-test   - Test current TrackPoint settings"

# Clone and install using the official script
install: deps
	@if [ ! -d "throttled" ]; then \
		git clone https://github.com/erpalma/throttled.git; \
	fi
	cd throttled && ./install.sh

# Clean up repository
clean:
	rm -rf throttled