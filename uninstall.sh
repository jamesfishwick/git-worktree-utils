#!/usr/bin/env bash
# Git Worktree Utils - Uninstallation Script

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Installation directories
INSTALL_DIR="${HOME}/.config/git-worktree-utils"

# Print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Header
echo
print_color "$BLUE" "==================================="
print_color "$BLUE" "  Git Worktree Utils Uninstaller"
print_color "$BLUE" "==================================="
echo

# Confirm uninstallation
print_color "$YELLOW" "This will remove Git Worktree Utils from your system."
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_color "$RED" "✗ Uninstallation cancelled"
    exit 1
fi

# Detect shell RC file
SHELL_NAME=$(basename "$SHELL")
SHELL_RC=""

case "$SHELL_NAME" in
    bash)
        SHELL_RC="${HOME}/.bashrc"
        if [[ ! -f "$SHELL_RC" ]]; then
            SHELL_RC="${HOME}/.bash_profile"
        fi
        ;;
    zsh)
        SHELL_RC="${HOME}/.zshrc"
        ;;
    *)
        SHELL_RC="${HOME}/.bashrc"
        ;;
esac

# Remove from shell RC
if [[ -f "$SHELL_RC" ]]; then
    print_color "$YELLOW" "→ Removing from $SHELL_RC..."
    
    # Create backup
    cp "$SHELL_RC" "${SHELL_RC}.backup.uninstall.$(date +%Y%m%d_%H%M%S)"
    print_color "$GREEN" "✓ Created backup"
    
    # Remove the source lines
    sed -i.tmp '/# Git Worktree Utils/,/^fi$/d' "$SHELL_RC"
    rm -f "${SHELL_RC}.tmp"
    
    print_color "$GREEN" "✓ Removed from shell configuration"
fi

# Ask about configuration
if [[ -d "$INSTALL_DIR" ]]; then
    print_color "$YELLOW" "→ Configuration directory found: $INSTALL_DIR"
    read -p "Keep configuration for future use? (Y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        rm -rf "$INSTALL_DIR"
        print_color "$GREEN" "✓ Removed configuration directory"
    else
        # Remove scripts but keep config
        rm -f "${INSTALL_DIR}/git-worktree-utils.sh"
        print_color "$GREEN" "✓ Removed scripts (configuration preserved)"
    fi
fi

# Success
echo
print_color "$GREEN" "==================================="
print_color "$GREEN" "  Uninstallation Complete"
print_color "$GREEN" "==================================="
echo
print_color "$YELLOW" "Please restart your shell or start a new session"
print_color "$YELLOW" "to complete the removal."
echo
