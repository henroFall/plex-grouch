#!/bin/bash

echo "🐸 Installing Plex-Grouch... Oscar is getting ready to take out the trash!"

# Default base directory
DEFAULT_BASE_DIR="/mnt"

# Ask the user where their NAS directories are located
read -p "Enter base directory for NAS mounts (default: $DEFAULT_BASE_DIR): " BASE_DIR
BASE_DIR="${BASE_DIR:-$DEFAULT_BASE_DIR}"

# Verify the directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "ERROR: The specified directory does not exist!"
    exit 1
fi

echo "Using base directory: $BASE_DIR"

# Create or reset the config file
CONFIG_FILE="/etc/plex-grouch.conf"
> "$CONFIG_FILE"

# Ask user for the Plex API Token
read -p "Enter your Plex API Token: " PLEX_TOKEN
PLEX_ENV_FILE="/etc/plex-grouch.env"
echo "PLEX_TOKEN=$PLEX_TOKEN" | sudo tee "$PLEX_ENV_FILE" > /dev/null
sudo chmod 600 "$PLEX_ENV_FILE"
echo "✅ Plex API Token saved in $PLEX_ENV_FILE"

# Iterate through subdirectories and ask user to include them
echo "Scanning $BASE_DIR for NAS folders..."
for NAS in "$BASE_DIR"/*/; do
    [ -d "$NAS" ] || continue  # Skip non-directories
    NAS=${NAS%/}  # Remove trailing slash

    # Ask user whether to include this directory
    read -p "Include $NAS for monitoring? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$NAS" >> "$CONFIG_FILE"
        touch "$NAS/test.nas"  # Ensure test.nas exists
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
sudo cp plex-grouch.timer /etc/systemd/system/

# Reload systemd and enable the timer
sudo systemctl daemon-reload
sudo systemctl enable plex-grouch.timer
sudo systemctl start plex-grouch.timer

echo "✅ Installation complete! Oscar will check the trash every hour."
echo "📝 Configured NAS paths (modify if needed):"
cat "$CONFIG_FILE"
