.PHONY: change-hostname backup-hostname show-current

# Check if running with sudo
check-sudo:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "This target must be run with sudo"; \
		exit 1; \
	fi

# Show current hostname settings
show-current:
	@echo "Current hostname settings:"
	@echo "-------------------------"
	@echo "Hostname: $$(hostname)"
	@echo "Machine ID: $$(cat /etc/machine-id)"
	@echo "Hosts file content:"
	@cat /etc/hosts

# Backup current hostname files
backup-hostname:
	@echo "Creating backups..."
	@sudo cp /etc/hostname /etc/hostname.backup
	@sudo cp /etc/hosts /etc/hosts.backup
	@echo "Backups created: /etc/hostname.backup and /etc/hosts.backup"

# Change hostname (usage: sudo make change-hostname NEW_HOSTNAME=your-new-hostname)
change-hostname: check-sudo backup-hostname
	@if [ -z "$(NEW_HOSTNAME)" ]; then \
		echo "Error: NEW_HOSTNAME is required. Usage: sudo make change-hostname NEW_HOSTNAME=your-new-hostname"; \
		exit 1; \
	fi
	@echo "Changing hostname to $(NEW_HOSTNAME)..."
	@echo "$(NEW_HOSTNAME)" | sudo tee /etc/hostname
	@sudo hostnamectl set-hostname "$(NEW_HOSTNAME)"
	@sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$(NEW_HOSTNAME)/" /etc/hosts
	@echo "Hostname changed successfully. Please reboot your system for changes to take full effect."

# Restore from backup
restore-backup: check-sudo
	@if [ -f /etc/hostname.backup ] && [ -f /etc/hosts.backup ]; then \
		sudo mv /etc/hostname.backup /etc/hostname; \
		sudo mv /etc/hosts.backup /etc/hosts; \
		echo "Hostname configuration restored from backup"; \
	else \
		echo "Backup files not found"; \
		exit 1; \
	fi