#!/bin/bash

echo "🗑️ Uninstalling Plex-Grouch... Oscar is leaving!"

# Stop and disable the service and timer
sudo systemctl stop plex-grouch.timer
sudo systemctl disable plex-grouch.timer

# Remove service and timer files
sudo rm -f /etc/systemd/system/plex-grouch.service
sudo rm -f /etc/systemd/system/plex-grouch.timer

# Remove the main script
sudo rm -f /usr/local/bin/plex-grouch.sh

# Remove configuration and logs
sudo rm -f /etc/plex-grouch.conf
sudo rm -f /var/log/plex-grouch.log
sudo rm -f /etc/logrotate.d/plex-grouch
sudo rm -f /etc/plex-grouch.env

# Reload systemd daemon
sudo systemctl daemon-reload

echo "✅ Plex-Grouch has been completely uninstalled."
