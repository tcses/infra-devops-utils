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

# Clone and install using the official script
install: deps
	@if [ ! -d "throttled" ]; then \
		git clone https://github.com/erpalma/throttled.git; \
	fi
	cd throttled && ./install.sh

# Clean up repository
clean:
	rm -rf throttled