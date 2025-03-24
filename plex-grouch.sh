#!/bin/bash

# Configuration and log files
CONFIG_FILE="/etc/plex-grouch.conf"
LOG_FILE="/var/log/plex-grouch.log"
PLEX_ENV_FILE="/etc/plex-grouch.env"

# Ensure Plex API Token file exists
if [ ! -f "$PLEX_ENV_FILE" ]; then
    echo "$(date): ERROR - I dug all around this can and the Plex API Token file is not where it is supposed to be at $PLEX_ENV_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Load Plex API Token
source "$PLEX_ENV_FILE"

# Ensure configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "$(date): ERROR - I dug all around this can and the config file is not found at $CONFIG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Read NAS mount points and selected sections from config file
NAS_MOUNTS=()
SECTIONS=()
while IFS= read -r line; do
    if [[ "$line" == SECTIONS=* ]]; then
        IFS=' ' read -r -a SECTIONS <<< "${line#SECTIONS=}"
    else
        NAS_MOUNTS+=("$line")
    fi 
done < "$CONFIG_FILE"

# Check if all NAS directories are mounted
ALL_MOUNTED=true
for NAS in "${NAS_MOUNTS[@]}"; do
    if [ ! -f "$NAS/test.nas" ]; then
        echo "$(date): ERROR - SCRAM! Your network sucks! $NAS is not mounted." | tee -a "$LOG_FILE"
        ALL_MOUNTED=false
    fi
done

# If all NAS directories are mounted, proceed to scan then empty trash
if [ "$ALL_MOUNTED" = true ]; then
  echo "$(date): GROUCH - Well, good! Everything is where it should be. I'll scan first, then empty the trash." | tee -a "$LOG_FILE"

  # Start scanning libraries in background
  for SECTION_ID in "${SECTIONS[@]}"; do
    echo "$(date): GROUCH - Kicking off scan for section ID $SECTION_ID." | tee -a "$LOG_FILE"
    curl -s -X POST "http://localhost:32400/library/sections/$SECTION_ID/refresh?X-Plex-Token=$PLEX_TOKEN" &
  done

  # Wait for all background scan curl jobs to finish
  wait
  echo "$(date): GROUCH - All scan requests completed. Waiting 2 more minutes to let Plex do its thing..." | tee -a "$LOG_FILE"
  sleep 120

  # Now empty the trash
  for SECTION_ID in "${SECTIONS[@]}"; do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "http://localhost:32400/library/sections/$SECTION_ID/emptyTrash?X-Plex-Token=$PLEX_TOKEN")
    if [ "$RESPONSE" -eq 200 ]; then
      echo "$(date): GROUCH - Great, you managed to keep your network together for another hour! I just emptied the trash for section ID $SECTION_ID." | tee -a "$LOG_FILE"
    else
      echo "$(date): ERROR - SCRAM! Failed to empty trash for section ID $SECTION_ID. HTTP response code: $RESPONSE" | tee -a "$LOG_FILE"
    fi
  done

else
    echo "$(date): Not all NAS directories are mounted. Skipping trash emptying. SCRAM!" | tee -a "$LOG_FILE"
fi
