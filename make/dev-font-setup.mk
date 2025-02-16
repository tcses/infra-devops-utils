.PHONY: install-fonts install-hack-font install-fira-font install-fira-code configure-vscode configure-gnome-terminal configure-all

# Install all fonts and configure terminals
configure-all: install-fonts configure-vscode configure-gnome-terminal
	@echo "All configurations completed successfully!"

# Install all fonts
install-fonts: install-hack-font install-fira-font install-fira-code
	@echo "All fonts installed successfully!"

# Install Hack Nerd Font
install-hack-font:
	@echo "Installing Hack Nerd Font..."
	@brew install --cask font-hack-nerd-font
	@echo "Hack Nerd Font installed successfully!"

# Install Fira Code font
install-fira-code:
	@echo "Installing Fira Code font..."
	@brew install --cask font-fira-code
	@echo "Fira Code font installed successfully!"

# Install Fira Mono Nerd Font
install-fira-font:
	@echo "Installing Fira Mono Nerd Font..."
	@brew install --cask font-fira-mono-nerd-font
	@echo "Fira Mono Nerd Font installed successfully!"

# Configure VSCode settings
configure-vscode:
	@echo "Configuring VSCode settings..."
	@mkdir -p $(HOME)/.config/Code/User
	@if [ ! -f "$(HOME)/.config/Code/User/settings.json" ]; then \
		echo '{"terminal.integrated.fontFamily": "Hack Nerd Font Mono","editor.fontFamily": "\"Fira Code\", \"Droid Sans Mono\", monospace","editor.fontSize": 14,"editor.fontLigatures": true,"terminal.integrated.fontSize": 14}' > "$(HOME)/.config/Code/User/settings.json"; \
	else \
		if ! grep -q "terminal.integrated.fontFamily" "$(HOME)/.config/Code/User/settings.json"; then \
			sed -i '1s/{/{\"terminal.integrated.fontFamily\": \"Hack Nerd Font Mono\",/' "$(HOME)/.config/Code/User/settings.json"; \
		else \
			sed -i 's/"terminal.integrated.fontFamily":[^,]*/"terminal.integrated.fontFamily": "Hack Nerd Font Mono"/g' "$(HOME)/.config/Code/User/settings.json"; \
		fi; \
		if ! grep -q "editor.fontFamily" "$(HOME)/.config/Code/User/settings.json"; then \
			sed -i '1s/{/{\"editor.fontFamily\": \"\\\"Fira Code\\\", \\\"Droid Sans Mono\\\", monospace\",/' "$(HOME)/.config/Code/User/settings.json"; \
		else \
			sed -i 's/"editor.fontFamily":[^,]*/"editor.fontFamily": "\"Fira Code\", \"Droid Sans Mono\", monospace"/g' "$(HOME)/.config/Code/User/settings.json"; \
		fi; \
		if ! grep -q "editor.fontSize" "$(HOME)/.config/Code/User/settings.json"; then \
			sed -i '1s/{/{\"editor.fontSize\": 14,/' "$(HOME)/.config/Code/User/settings.json"; \
		else \
			sed -i 's/"editor.fontSize":[^,]*/"editor.fontSize": 14/g' "$(HOME)/.config/Code/User/settings.json"; \
		fi; \
		if ! grep -q "editor.fontLigatures" "$(HOME)/.config/Code/User/settings.json"; then \
			sed -i '1s/{/{\"editor.fontLigatures\": true,/' "$(HOME)/.config/Code/User/settings.json"; \
		else \
			sed -i 's/"editor.fontLigatures":[^,]*/"editor.fontLigatures": true/g' "$(HOME)/.config/Code/User/settings.json"; \
		fi; \
		if ! grep -q "terminal.integrated.fontSize" "$(HOME)/.config/Code/User/settings.json"; then \
			sed -i '1s/{/{\"terminal.integrated.fontSize\": 14,/' "$(HOME)/.config/Code/User/settings.json"; \
		else \
			sed -i 's/"terminal.integrated.fontSize":[^,]*/"terminal.integrated.fontSize": 14/g' "$(HOME)/.config/Code/User/settings.json"; \
		fi \
	fi
	@echo "VSCode settings configured successfully!"

# Configure GNOME Terminal font
configure-gnome-terminal:
	@echo "Configuring GNOME Terminal font..."
	@PROFILE_ID=$$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'"); \
	if [ -n "$$PROFILE_ID" ]; then \
		CURRENT_FONT=$$(gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$$PROFILE_ID/ font); \
		if [ "$$CURRENT_FONT" != "'Hack Nerd Font Mono 12'" ]; then \
			gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$$PROFILE_ID/ font 'Hack Nerd Font Mono 12'; \
		fi; \
		SYSTEM_FONT=$$(gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$$PROFILE_ID/ use-system-font); \
		if [ "$$SYSTEM_FONT" != "false" ]; then \
			gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$$PROFILE_ID/ use-system-font false; \
		fi; \
		echo "GNOME Terminal font configured successfully!"; \
	else \
		echo "Error: Could not find default GNOME Terminal profile"; \
		exit 1; \
	fi