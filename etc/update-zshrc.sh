#!/bin/zsh

# Script for updating all .zshrc files on macOS
# Author: Generated script for zshrc update
# Usage: curl -fsSL https://git.recwebnetwork.com/etc/update-zshrc.sh | zsh

set -euo pipefail

# Configuration
URL="https://git.recwebnetwork.com/etc/zsh.zshrc"
THEME_URL="https://git.recwebnetwork.com/oh-my-posh/themes/recweb.omp.json"
TEMP_FILE="/tmp/new_zshrc_$$"
TEMP_THEME="/tmp/recweb_theme_$$.omp.json"
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

# Function for backup and file update
update_zshrc() {
    local file_path="$1"
    local owner="$2"
    local group="$3"

    if [[ -f "$file_path" ]]; then
        log "Creating backup for $file_path"
        cp "$file_path" "$file_path$BACKUP_SUFFIX"
    fi

    log "Updating $file_path"
    cp "$TEMP_FILE" "$file_path"

    # On macOS, use sudo chown only if we have permissions
    if [[ -w "$file_path" ]]; then
        chmod 644 "$file_path"
    else
        sudo chown "$owner:$group" "$file_path"
        sudo chmod 644 "$file_path"
    fi

    success "✓ Updated: $file_path"
}

# Function to install oh-my-posh theme for a user
install_theme() {
    local user_home="$1"
    local owner="$2"
    local use_sudo="$3"

    local theme_dir="$user_home/.config/oh-my-posh/themes"
    local theme_file="$theme_dir/recweb.omp.json"

    if [[ "$use_sudo" == "yes" ]]; then
        sudo mkdir -p "$theme_dir"
        sudo cp "$TEMP_THEME" "$theme_file"
        sudo chown -R "$owner:staff" "$user_home/.config/oh-my-posh"
        sudo chmod 644 "$theme_file"
    else
        mkdir -p "$theme_dir"
        cp "$TEMP_THEME" "$theme_file"
        chmod 644 "$theme_file"
    fi

    success "✓ Installed theme: $theme_file"
}

# Start the process
log "Starting .zshrc files update for macOS..."

# Download new content
log "Downloading content from $URL"
if ! curl -fsSL "$URL" -o "$TEMP_FILE"; then
    error "Could not download file from $URL"
    exit 1
fi

success "✓ Content downloaded successfully"

# Download oh-my-posh theme
log "Downloading oh-my-posh theme from $THEME_URL"
if ! curl -fsSL "$THEME_URL" -o "$TEMP_THEME"; then
    warning "Could not download theme from $THEME_URL (will skip theme installation)"
    THEME_AVAILABLE="no"
else
    success "✓ Theme downloaded successfully"
    THEME_AVAILABLE="yes"
fi

# Detect if running as root or regular user
RUNNING_USER=$(whoami)
log "Running as user: $RUNNING_USER"

# Update system-wide zshrc (requires sudo)
if [[ -f "/etc/zshrc" ]]; then
    log "Updating /etc/zshrc (requires sudo)..."
    if sudo -n true 2>/dev/null; then
        if [[ -f "/etc/zshrc" ]]; then
            sudo cp "/etc/zshrc" "/etc/zshrc$BACKUP_SUFFIX" 2>/dev/null || true
        fi
        sudo cp "$TEMP_FILE" "/etc/zshrc"
        sudo chmod 644 "/etc/zshrc"
        success "✓ Updated: /etc/zshrc"
    else
        warning "No sudo access, skipping /etc/zshrc"
    fi
fi

# Update current user's .zshrc
log "Updating ~/.zshrc for current user ($RUNNING_USER)..."
HOME_ZSHRC="$HOME/.zshrc"
update_zshrc "$HOME_ZSHRC" "$RUNNING_USER" "staff"

# Install theme for current user
if [[ "$THEME_AVAILABLE" == "yes" ]]; then
    log "Installing oh-my-posh theme for current user..."
    install_theme "$HOME" "$RUNNING_USER" "no"
fi

# If running with sudo privileges, offer to update other users
if sudo -n true 2>/dev/null; then
    log "Checking for other users in /Users..."

    for home_dir in /Users/*/; do
        if [[ -d "$home_dir" ]]; then
            username=$(basename "$home_dir")

            # Skip system users and current user
            if [[ "$username" == "Shared" ]] || \
               [[ "$username" == "Guest" ]] || \
               [[ "$username" == "$RUNNING_USER" ]]; then
                continue
            fi

            zshrc_file="${home_dir}.zshrc"

            # Check if user exists in system
            if id "$username" &>/dev/null; then
                log "Updating for user: $username"

                # Backup if exists
                if [[ -f "$zshrc_file" ]]; then
                    sudo cp "$zshrc_file" "$zshrc_file$BACKUP_SUFFIX"
                fi

                # Copy new file
                sudo cp "$TEMP_FILE" "$zshrc_file"
                sudo chown "$username:staff" "$zshrc_file"
                sudo chmod 644 "$zshrc_file"

                success "✓ Updated: $zshrc_file"

                # Install theme for user
                if [[ "$THEME_AVAILABLE" == "yes" ]]; then
                    install_theme "$home_dir" "$username" "yes"
                fi
            else
                warning "User $username does not exist in system, skipping $zshrc_file"
            fi
        fi
    done
else
    warning "No sudo access - only updated current user's .zshrc"
    warning "To update all users, run with sudo privileges"
fi

# Clean up temporary files
rm -f "$TEMP_FILE"
rm -f "$TEMP_THEME"

echo
success "==========================================="
success "✓ All .zshrc files have been updated!"
if [[ "$THEME_AVAILABLE" == "yes" ]]; then
    success "✓ Oh-my-posh theme installed!"
fi
success "✓ Backups created with suffix: $BACKUP_SUFFIX"
success "==========================================="
echo
log "To activate new settings:"
log "  - Close and reopen terminal OR"
log "  - Run: source ~/.zshrc"
echo
warning "NOTE: For oh-my-posh to work, install it with Homebrew:"
warning "  brew install jandedobbeleer/oh-my-posh/oh-my-posh"
echo
log "Theme installed in: ~/.config/oh-my-posh/themes/recweb.omp.json"
