#!/usr/bin/env bash
# Git Worktree Utils - Installation Script

# Safer shell options (portable across bash/zsh)
set -e
set -u
set -o pipefail 2>/dev/null || true

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    local color=$1
    shift
    printf '%b\n' "${color}$*${NC}"
}

# Error trap with helpful message
on_error() {
    local ec=$?
    print_color "$RED" "Error on line ${LINENO}. Exiting (code: ${ec})."
    exit "$ec"
}

# Set trap per-shell
if [[ -n ${BASH_VERSION:-} ]]; then
    trap on_error ERR
elif [[ -n ${ZSH_VERSION:-} ]]; then
    trap on_error ZERR
fi

# Installation directories (XDG aware)
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
INSTALL_DIR="${CONFIG_HOME}/git-worktree-utils"
CONFIG_FILE="${INSTALL_DIR}/config"

# Determine script location (works in bash and zsh when executed)
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
SCRIPT_FILE="${SCRIPT_DIR}/git-worktree-utils.sh"

# Header
echo
print_color "$BLUE" "==================================="
print_color "$BLUE" "  Git Worktree Utils Installer"
print_color "$BLUE" "==================================="
echo

# Check for git
if ! command -v git &> /dev/null; then
    print_color "$RED" "✗ Git is not installed. Please install git first."
    exit 1
fi

print_color "$GREEN" "✓ Git found: $(git --version)"

# Check git version (worktrees need git 2.5+)
GIT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
REQUIRED_VERSION="2.5"

if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$GIT_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    print_color "$RED" "✗ Git version $GIT_VERSION is too old. Need at least $REQUIRED_VERSION"
    exit 1
fi

# Detect login shell and choose RC file (prefer zsh when present)
SHELL_NAME="${SHELL##*/}"
SHELL_RC=""

case "$SHELL_NAME" in
    bash)
        SHELL_RC="${HOME}/.bashrc"
        if [[ ! -f "$SHELL_RC" && -f "${HOME}/.bash_profile" ]]; then
            SHELL_RC="${HOME}/.bash_profile"
        fi
        ;;
    zsh)
        SHELL_RC="${HOME}/.zshrc"
        ;;
    *)
        print_color "$YELLOW" "⚠️  Unknown shell: $SHELL_NAME"
        # Prefer existing zsh rc, then bash rc; default to zsh if neither exists
        if [[ -f "${HOME}/.zshrc" ]]; then
            SHELL_RC="${HOME}/.zshrc"
        elif [[ -f "${HOME}/.bashrc" ]]; then
            SHELL_RC="${HOME}/.bashrc"
        else
            SHELL_RC="${HOME}/.zshrc"
        fi
        ;;
esac

print_color "$GREEN" "✓ Detected shell: $SHELL_NAME"
print_color "$GREEN" "✓ Shell config: $SHELL_RC"

# Create installation directory
print_color "$YELLOW" "→ Creating configuration directory..."
mkdir -p "$INSTALL_DIR"

# Copy main script and help file
print_color "$YELLOW" "→ Installing scripts..."
if [[ -f "$SCRIPT_FILE" ]]; then
    if command -v install >/dev/null 2>&1; then
        install -m 0755 "$SCRIPT_FILE" "${INSTALL_DIR}/git-worktree-utils.sh"
    else
        cp "$SCRIPT_FILE" "$INSTALL_DIR/"
        chmod +x "${INSTALL_DIR}/git-worktree-utils.sh"
    fi
    print_color "$GREEN" "✓ Installed git-worktree-utils.sh"
else
    print_color "$RED" "✗ Cannot find git-worktree-utils.sh"
    exit 1
fi

# Copy help file
HELP_FILE="${SCRIPT_DIR}/git-worktree-utils-help.sh"
if [[ -f "$HELP_FILE" ]]; then
    if command -v install >/dev/null 2>&1; then
        install -m 0644 "$HELP_FILE" "${INSTALL_DIR}/git-worktree-utils-help.sh"
    else
        cp "$HELP_FILE" "$INSTALL_DIR/"
    fi
    print_color "$GREEN" "✓ Installed git-worktree-utils-help.sh"
else
    print_color "$YELLOW" "⚠️  Help file not found (help will be unavailable)"
fi

# Create default config if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    print_color "$YELLOW" "→ Creating default configuration..."
    cat > "$CONFIG_FILE" << 'EOF'
# Git Worktree Utils Configuration
# Edit this file to customize behavior

# Auto-prune broken worktrees on every wt command
GWT_AUTO_PRUNE=true

# Prompt before deleting directories
GWT_CONFIRM_DELETE=true

# Directory patterns to search for during cleanup
# Space-separated list of patterns (relative to parent directory)
GWT_CLEANUP_PATTERNS="*-feature* *-hotfix* *-release* *-review* *-epic* *-experiment*"

# Directory naming pattern (future feature)
# {base} = current directory name
# {branch} = sanitized branch name
GWT_DIR_PATTERN="{base}-{branch}"

# Enable colored output
GWT_USE_COLOR=true
EOF
    print_color "$GREEN" "✓ Created default configuration"
else
    print_color "$GREEN" "✓ Configuration already exists (preserved)"
fi

# Add to shell RC file
print_color "$YELLOW" "→ Updating shell configuration..."

GWT_MARKER_BEGIN="# >>> Git Worktree Utils"

# Ensure RC file exists; back up only if it pre-existed
if [[ -f "$SHELL_RC" ]]; then
    :
else
    print_color "$YELLOW" "→ Creating $SHELL_RC"
    : > "$SHELL_RC"
fi

# Check if already installed using marker
if grep -Fq "${GWT_MARKER_BEGIN}" "$SHELL_RC" 2>/dev/null; then
    print_color "$YELLOW" "⚠️  Already configured in $SHELL_RC (skipping)"
else
    if [[ -s "${SHELL_RC}" ]]; then
        cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"
        print_color "$GREEN" "✓ Created backup: ${SHELL_RC}.backup.*"
    fi
    cat >> "$SHELL_RC" << 'EOF'

# >>> Git Worktree Utils
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
if [[ -f "${CONFIG_HOME}/git-worktree-utils/git-worktree-utils.sh" ]]; then
  source "${CONFIG_HOME}/git-worktree-utils/git-worktree-utils.sh"
elif [[ -f "${HOME}/.config/git-worktree-utils/git-worktree-utils.sh" ]]; then
  # Legacy fallback
  source "${HOME}/.config/git-worktree-utils/git-worktree-utils.sh"
fi
# <<< Git Worktree Utils
EOF
    print_color "$GREEN" "✓ Added to $SHELL_RC"
fi

# Run shellcheck if available
if command -v shellcheck &> /dev/null; then
    print_color "$YELLOW" "→ Running shellcheck validation..."
    if shellcheck "${INSTALL_DIR}/git-worktree-utils.sh"; then
        print_color "$GREEN" "✓ Scripts pass shellcheck"
    else
        print_color "$YELLOW" "⚠️  Shellcheck found warnings (non-critical)"
    fi
else
    print_color "$YELLOW" "ℹ️  Shellcheck not found (skipping validation)"
fi

# Test the functions
print_color "$YELLOW" "→ Testing installation..."
(
    # shellcheck source=/dev/null
    source "${INSTALL_DIR}/git-worktree-utils.sh"
    if type wt &> /dev/null; then
        print_color "$GREEN" "✓ Functions loaded successfully"
    else
        print_color "$RED" "✗ Functions failed to load"
        exit 1
    fi
)

# Success message
echo
print_color "$GREEN" "==================================="
print_color "$GREEN" "   Installation Complete! 🎉"
print_color "$GREEN" "==================================="
echo
print_color "$BLUE" "Next steps:"
echo "  1. Restart your shell or run:"
echo "     source \"$SHELL_RC\""
echo
echo "  2. Try the commands:"
echo "     wt              # List worktrees"
echo "     wthelp          # Show help"
echo
echo "  3. Edit configuration (optional):"
echo "     $CONFIG_FILE"
echo
print_color "$BLUE" "Documentation: https://github.com/yourusername/git-worktree-utils"
echo
