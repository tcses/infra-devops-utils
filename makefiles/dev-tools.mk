# In your central repo, create a dev-tools.mk file:
# dev-tools.mk

# Detect OS
OS := $(shell cat /etc/os-release | grep ^ID= | cut -d= -f2 | tr -d '"')

# Default theme for Oh My Posh
POSH_THEME ?= jandedobbeleer

# Homebrew installation
define install_brew
	@if ! . ~/.bashrc && command -v brew >/dev/null 2>&1; then \
		echo "Installing Homebrew and dependencies..."; \
		if [ "$(OS)" = "debian" ]; then \
			sudo apt-get update && \
			sudo apt-get install -y build-essential curl file git procps; \
		fi; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo 'eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc; \
		echo 'eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bash_profile; \
		. ~/.bashrc; \
		export PATH="/home/linuxbrew/.linuxbrew/bin:$$PATH"; \
		eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		brew install gcc; \
	else \
		echo "Homebrew is already installed."; \
		. ~/.bashrc; \
		export PATH="/home/linuxbrew/.linuxbrew/bin:$$PATH"; \
		eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
	fi
endef

# Helper function to install or upgrade a package
define brew_install_or_upgrade
	@( \
		. ~/.bashrc; \
		export PATH="/home/linuxbrew/.linuxbrew/bin:$$PATH"; \
		eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"; \
		if ! command -v $(1) >/dev/null 2>&1; then \
			echo "Installing $(1)..."; \
			brew install $(2); \
		else \
			echo "$(1) is already installed. Running brew upgrade..."; \
			brew upgrade $(2) || true; \
		fi \
	)
	@echo "$(1) installation complete!"
endef

# Individual tool installation targets
install-k9s: install-brew
	$(call brew_install_or_upgrade,k9s,k9s)

install-ctop: install-brew
	$(call brew_install_or_upgrade,ctop,ctop)

install-glances: install-brew
	$(call brew_install_or_upgrade,glances,glances)

install-jq: install-brew
	$(call brew_install_or_upgrade,jq,jq)

install-yq: install-brew
	$(call brew_install_or_upgrade,yq,yq)

install-ranger: install-brew
	$(call brew_install_or_upgrade,ranger,ranger)

install-gh: install-brew
	$(call brew_install_or_upgrade,gh,gh)

# Group installation targets
install-container-tools: install-k9s install-ctop
	@echo "Container tools installation complete!"

install-monitoring-tools: install-glances
	@echo "Monitoring tools installation complete!"

install-json-tools: install-jq install-yq
	@echo "JSON/YAML tools installation complete!"

install-dev-tools: install-container-tools install-monitoring-tools install-json-tools install-ranger install-gh
	@echo "All developer tools installation complete!"

# Oh My Posh installation
define install_oh_my_posh
	@echo "Installing Oh My Posh for $(OS)..."
	@. ~/.bashrc && brew install jandedobbeleer/oh-my-posh/oh-my-posh
	@if ! grep -q "oh-my-posh" ~/.bashrc; then \
		echo "Adding Oh My Posh initialization to ~/.bashrc..."; \
		echo 'eval "$$(oh-my-posh init bash --config $$(brew --prefix oh-my-posh)/themes/$(POSH_THEME).omp.json)"' >> ~/.bashrc; \
	fi
	@if ! grep -q "oh-my-posh" ~/.bash_profile; then \
		echo "Adding Oh My Posh initialization to ~/.bash_profile..."; \
		echo 'eval "$$(oh-my-posh init bash --config $$(brew --prefix oh-my-posh)/themes/$(POSH_THEME).omp.json)"' >> ~/.bash_profile; \
	fi
	@test -f ~/.bashrc || touch ~/.bashrc
	@if ! grep -q "source.*\.bashrc" ~/.bash_profile; then \
		echo "Ensuring .bash_profile sources .bashrc..."; \
		echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> ~/.bash_profile; \
	fi
endef

install-oh-my-posh: install-brew
	$(call install_oh_my_posh)
	@echo "Oh My Posh installation complete!"
	@echo "Please restart your terminal or run 'source ~/.bashrc' to apply changes"
	@echo "You can change themes by modifying the POSH_THEME variable"

# Install everything
install-all: install-oh-my-posh install-dev-tools
	@echo "All tools installation complete!"

.PHONY: install-brew install-k9s install-ctop install-glances install-jq install-yq \
	install-ranger install-gh install-container-tools install-monitoring-tools \
	install-json-tools install-dev-tools install-oh-my-posh install-all

# Then in your project's Makefile:
# Makefile

# Include the centralized dev tools
DEVTOOLS_REPO ?= https://raw.githubusercontent.com/your-username/your-repo/main
DEVTOOLS_PATH ?= $(shell pwd)/.make

$(DEVTOOLS_PATH)/dev-tools.mk:
	@mkdir -p $(DEVTOOLS_PATH)
	@curl -s -o $@ $(DEVTOOLS_REPO)/dev-tools.mk

-include $(DEVTOOLS_PATH)/dev-tools.mk

# Your existing Makefile targets continue below...
