#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "🐸 Installing Plex-Grouch... Oscar is getting ready to take out the trash!"

# Default base directory
DEFAULT_BASE_DIR="/mnt"

# Ask the user where their NAS directories are located
read -rp "Enter base directory for NAS mounts (default: $DEFAULT_BASE_DIR): " BASE_DIR
BASE_DIR="${BASE_DIR:-$DEFAULT_BASE_DIR}"

# Verify the directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "ERROR: The specified directory does not exist!"
    exit 1
fi

echo "Using base directory: $BASE_DIR"

# Create or reset the config file
CONFIG_FILE="/etc/plex-grouch.conf"
sudo touch "$CONFIG_FILE"
sudo chmod 644 "$CONFIG_FILE"
> "$CONFIG_FILE"

# Create or reset the log file
LOG_FILE="/var/log/plex-grouch.log"
sudo touch "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"
echo "✅ Log file created at $LOG_FILE"

# Ask user for the Plex API Token
read -rp "Enter your Plex API Token: " PLEX_TOKEN
PLEX_ENV_FILE="/etc/plex-grouch.env"
echo "PLEX_TOKEN=$PLEX_TOKEN" | sudo tee "$PLEX_ENV_FILE" > /dev/null
sudo chmod 600 "$PLEX_ENV_FILE"
echo "✅ Plex API Token saved in $PLEX_ENV_FILE"

# Retrieve Plex library sections
echo "Retrieving Plex library sections..."
SECTIONS_XML=$(curl -s "http://localhost:32400/library/sections?X-Plex-Token=$PLEX_TOKEN")
if [[ -z "$SECTIONS_XML" ]]; then
    echo "ERROR: Unable to retrieve library sections. Please check your Plex Token and server status."
    exit 1
fi

# Parse and display sections
echo "Available Plex library sections:"
echo "$SECTIONS_XML" | grep -oP 'key="\K\d+' | while read -r key; do
    title=$(echo "$SECTIONS_XML" | grep -oP "key=\"$key\".*?title=\"\K[^\"]+")
    echo "[$key] $title"
done

# Prompt user to select sections
SELECTED_SECTIONS=()
while true; do
    read -rp "Enter the key of the section to monitor (or 'done' to finish): " SECTION_KEY
    if [[ "$SECTION_KEY" == "done" ]]; then
        break
    elif [[ "$SECTIONS_XML" == *"key=\"$SECTION_KEY\""* ]]; then
        SELECTED_SECTIONS+=("$SECTION_KEY")
        echo "✅ Section $SECTION_KEY added."
    else
        echo "❌ Invalid section key. Please try again."
    fi
done

# Save selected sections to config
if [ ${#SELECTED_SECTIONS[@]} -eq 0 ]; then
    echo "ERROR: No library sections selected. Exiting."
    exit 1
fi

echo "Selected sections: ${SELECTED_SECTIONS[*]}"
echo "SECTIONS=${SELECTED_SECTIONS[*]}" | sudo tee -a "$CONFIG_FILE" > /dev/null

# Iterate through subdirectories and ask user to include them
echo "Scanning $BASE_DIR for NAS folders..."
for NAS in "$BASE_DIR"/*/; do
    [ -d "$NAS" ] || continue  # Skip non-directories
    NAS=${NAS%/}  # Remove trailing slash

    # Ask user whether to include this directory
    read -rp "Include $NAS for monitoring? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$NAS" | sudo tee -a "$CONFIG_FILE" > /dev/null
        sudo touch "$NAS/test.nas"  # Ensure test.nas exists
        echo "✅ Added $NAS"
    else
        echo "❌ Skipped $NAS"
    fi
done

# Verify at least one NAS is selected
if [ ! -s "$CONFIG_FILE" ]; then
    echo "ERROR: No NAS directories selected. Exiting."
    exit 1
fi

# Install log rotation
LOGROTATE_CONFIG="/etc/logrotate.d/plex-grouch"
if [ ! -f "$LOGROTATE_CONFIG" ]; then
    echo "Creating logrotate configuration..."
    cat <<EOF | sudo tee "$LOGROTATE_CONFIG" > /dev/null
/var/log/plex-grouch.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 root root
}
EOF
    echo "✅ Logrotate installed."
fi

# Copy main script
sudo cp plex-grouch.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/plex-grouch.sh

# Copy systemd service files
sudo cp plex-grouch.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/plex-grouch.service
sudo cp plex-grouch.timer /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/plex-grouch.timer

# Reload systemd and enable the timer
sudo systemctl daemon-reload
sudo systemctl enable plex-grouch.timer
sudo systemctl start plex-grouch.timer

echo "✅ Installation complete! Oscar will check the trash every hour."
echo "📝 Configured NAS paths (modify if needed):"
cat "$CONFIG_FILE"
