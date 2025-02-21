#!/bin/bash

# Configuration file storing NAS directories
CONFIG_FILE="/etc/plex-grouch.conf"
LOG_FILE="/var/log/plex-grouch.log"
PLEX_ENV_FILE="/etc/plex-grouch.env"

# Ensure Plex API Token exists
if [ ! -f "$PLEX_ENV_FILE" ]; then
    echo "$(date): ERROR - Plex API Token file not found at $PLEX_ENV_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Load Plex API Token
source "$PLEX_ENV_FILE"

# Read NAS mount points from config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "$(date): ERROR - Config file not found at $CONFIG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

mapfile -t NAS_MOUNTS < "$CONFIG_FILE"

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
