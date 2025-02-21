#!/bin/bash

# Configuration file storing NAS directories
CONFIG_FILE="/etc/plex-grouch.conf"
LOG_FILE="/var/log/plex-grouch.log"
LOGROTATE_CONFIG="/etc/logrotate.d/plex-grouch"

# Read NAS mount points from config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "$(date): SCRAM! Config file not found at $CONFIG_FILE. No cleanup for you!" | tee -a "$LOG_FILE"
    exit 1
fi

# Ensure logrotate configuration exists
if [ ! -f "$LOGROTATE_CONFIG" ]; then
    echo "Creating logrotate configuration for Plex-Grouch..."
    cat <<EOF | sudo tee "$LOGROTATE_CONFIG" > /dev/null
$LOG_FILE {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 root root
}
EOF
    echo "Logrotate configuration installed."
fi

# Read NAS mount points into an array
mapfile -t NAS_MOUNTS < "$CONFIG_FILE"

# Plex API Token (Replace with your actual token)
PLEX_TOKEN="YOUR_PLEX_TOKEN"

# Check for the presence of test.nas in all NAS mount points
ALL_CONNECTED=true
for NAS in "${NAS_MOUNTS[@]}"; do
    if [ ! -f "$NAS/test.nas" ]; then
        echo "$(date): SCRAM! Missing test.nas in $NAS. No cleanup today!" | tee -a "$LOG_FILE"
        ALL_CONNECTED=false
    fi
done

# If all NAS devices are connected, clean Plex trash
if $ALL_CONNECTED; then
    echo "$(date): Amazing! You managed to keep your network together! The trash is all mine!" | tee -a "$LOG_FILE"
    curl -X PUT "http://localhost:32400/library/clean?X-Plex-Token=$PLEX_TOKEN"
else
    echo "$(date): Keep your junk out of my trash can! Skipping Plex trash cleanup due to missing NAS devices." | tee -a "$LOG_FILE"
fi
