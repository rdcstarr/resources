#!/bin/bash

# Script for updating all .bashrc files
# Author: Generated script for bashrc update
# Usage: wget -qO- https://git.recwebnetwork.com/etc/update-bashrc.sh | bash

set -euo pipefail

# Configuration
URL="https://git.recwebnetwork.com/etc/bash.bashrc"
TEMP_FILE="/tmp/new_bashrc_$"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if script is running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root!"
    exit 1
fi

# Function for backup and file update
update_bashrc() {
    local file_path="$1"
    local owner="$2"
    local group="$3"

    if [[ -f "$file_path" ]]; then
        log "Creating backup for $file_path"
        cp "$file_path" "$file_path$BACKUP_SUFFIX"
    fi

    log "Updating $file_path"
    cp "$TEMP_FILE" "$file_path"
    chown "$owner:$group" "$file_path"
    chmod 644 "$file_path"

    success "✓ Updated: $file_path"
}

# Start the process
log "Starting .bashrc files update..."

# Download new content
log "Downloading content from $URL"
if ! curl -fsSL "$URL" -o "$TEMP_FILE"; then
    error "Could not download file from $URL"
    exit 1
fi

success "✓ Content downloaded successfully"

# Update /etc/bash.bashrc
log "Updating /etc/bash.bashrc..."
update_bashrc "/etc/bash.bashrc" "root" "root"

# Update ~/.bashrc for root
log "Updating ~/.bashrc for root..."
update_bashrc "/root/.bashrc" "root" "root"

# Update for all users in /home
log "Updating ~/.bashrc for all users..."

for home_dir in /home/*/; do
    if [[ -d "$home_dir" ]]; then
        username=$(basename "$home_dir")
        bashrc_file="$home_dir.bashrc"

        # Check if user exists in system
        if id "$username" &>/dev/null; then
            # Get user's GID
            user_group=$(id -gn "$username")

            log "Updating for user: $username"
            update_bashrc "$bashrc_file" "$username" "$user_group"
        else
            warning "User $username does not exist in system, skipping $bashrc_file"
        fi
    fi
done

# Clean up temporary file
rm -f "$TEMP_FILE"

echo
success "==========================================="
success "✓ All .bashrc files have been updated!"
success "✓ Backups created with suffix: $BACKUP_SUFFIX"
success "==========================================="
echo
log "To activate new settings, users need to:"
log "  - Reconnect OR"
log "  - Run: source ~/.bashrc"
echo
warning "NOTE: For oh-my-posh to work, it needs to be installed:"
warning "  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin"