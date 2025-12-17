#!/usr/bin/env bash
# Git Worktree Utils - Installation Script
# https://github.com/jamesfishwick/git-worktree-utils

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/jamesfishwick/git-worktree-utils"
RAW_URL="https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main"
INSTALL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git-worktree-utils"

# Helper functions
print_status() {
    printf "${BLUE}==>${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1" >&2
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

# Detect shell
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Get shell config file
get_shell_config() {
    local shell_type
    shell_type=$(detect_shell)

    case "$shell_type" in
        zsh)
            if [[ -f "$HOME/.zshrc" ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.zshrc"
            fi
            ;;
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Main installation
main() {
    echo ""
    print_status "Installing Git Worktree Utils"
    echo ""

    # Create installation directory
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_status "Creating directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
        print_success "Directory created"
    else
        print_warning "Directory already exists: $INSTALL_DIR"
    fi

    # Download main script
    print_status "Downloading git-worktree-utils.sh"
    if command -v curl > /dev/null 2>&1; then
        curl -fsSL "${RAW_URL}/git-worktree-utils.sh" -o "${INSTALL_DIR}/git-worktree-utils.sh"
    elif command -v wget > /dev/null 2>&1; then
        wget -q "${RAW_URL}/git-worktree-utils.sh" -O "${INSTALL_DIR}/git-worktree-utils.sh"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    print_success "Downloaded git-worktree-utils.sh"

    # Download example config if it doesn't exist
    if [[ ! -f "${INSTALL_DIR}/config" ]]; then
        print_status "Downloading config.example"
        if command -v curl > /dev/null 2>&1; then
            curl -fsSL "${RAW_URL}/config.example" -o "${INSTALL_DIR}/config.example"
        else
            wget -q "${RAW_URL}/config.example" -O "${INSTALL_DIR}/config.example"
        fi
        print_success "Downloaded config.example"
        print_warning "To customize: cp ${INSTALL_DIR}/config.example ${INSTALL_DIR}/config"
    else
        print_warning "Config file already exists, skipping"
    fi

    # Detect shell and suggest sourcing
    local shell_config
    shell_config=$(get_shell_config)

    echo ""
    print_success "Installation complete!"
    echo ""

    # Check if already sourced
    if [[ -n "$shell_config" ]] && [[ -f "$shell_config" ]]; then
        if grep -q "git-worktree-utils.sh" "$shell_config" 2>/dev/null; then
            print_success "Already sourced in: $shell_config"
        else
            print_status "Add this line to your $shell_config:"
            echo ""
            printf "    ${GREEN}source ${INSTALL_DIR}/git-worktree-utils.sh${NC}\n"
            echo ""
            read -p "Add automatically? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "" >> "$shell_config"
                echo "# Git Worktree Utils" >> "$shell_config"
                echo "source ${INSTALL_DIR}/git-worktree-utils.sh" >> "$shell_config"
                print_success "Added to $shell_config"
                print_warning "Restart your shell or run: source $shell_config"
            else
                print_warning "Skipped. Add the line manually when ready."
            fi
        fi
    else
        print_warning "Could not detect shell config file"
        print_status "Manually add this to your shell config:"
        echo ""
        printf "    ${GREEN}source ${INSTALL_DIR}/git-worktree-utils.sh${NC}\n"
        echo ""
    fi

    echo ""
    print_status "Quick Start:"
    echo "  gwt                    # List worktrees"
    echo "  gwt feature/new        # Create worktree"
    echo "  gwtlist                # Detailed info"
    echo "  gwtclean               # Cleanup orphans"
    echo "  gwthelp                # Full documentation"
    echo ""
    print_status "Learn more: ${REPO_URL}"
    echo ""
}

# Run installation
main "$@"
