.PHONY: install clean

# Determine OS and architecture
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/;s/\(arm64\|aarch64\)/arm64/')

install:
	@echo "Installing Gitpod CLI..."
	@curl -o gitpod -fsSL "https://releases.gitpod.io/cli/stable/gitpod-$(OS)-$(ARCH)"
	@chmod +x gitpod
	@sudo mv gitpod /usr/local/bin
	@echo "Gitpod CLI has been installed successfully!"

clean:
	@echo "Removing Gitpod CLI..."
	@sudo rm -f /usr/local/bin/gitpod
	@echo "Gitpod CLI has been removed."