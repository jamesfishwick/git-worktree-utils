#!/usr/bin/env bash
# Git Worktree Utils - Core Functions
# https://github.com/yourusername/git-worktree-utils

# shellcheck disable=SC2016  # Ignore backtick warnings for command substitution

# Load configuration (XDG aware with legacy fallback)
GWT_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
GWT_CONFIG_DIR="${GWT_CONFIG_HOME}/git-worktree-utils"
GWT_CONFIG_FILE="${GWT_CONFIG_DIR}/config"

# Legacy fallback to ~/.config if XDG location missing
if [[ ! -f "$GWT_CONFIG_FILE" ]]; then
    LEGACY_CONFIG_DIR="${HOME}/.config/git-worktree-utils"
    if [[ -f "${LEGACY_CONFIG_DIR}/config" ]]; then
        GWT_CONFIG_DIR="$LEGACY_CONFIG_DIR"
        GWT_CONFIG_FILE="${LEGACY_CONFIG_DIR}/config"
    fi
fi

# Default configuration
GWT_DIR_PATTERN="{base}-{branch}"
GWT_AUTO_PRUNE=true
GWT_CONFIRM_DELETE=true
GWT_CLEANUP_PATTERNS="*-feature* *-hotfix* *-release* *-review* *-epic*"

# Load user config if exists
if [[ -f "$GWT_CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$GWT_CONFIG_FILE"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print colored output
_gwt_print() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Helper function to parse worktree paths from --porcelain output
_gwt_get_worktree_paths() {
    git worktree list --porcelain | awk '/^worktree / {print $2}'
}

# Main worktree function
wt() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _gwt_print "$RED" "✗ Not in a git repository"
        return 1
    fi
    
    # If no argument, list worktrees
    if [[ -z "$1" ]]; then
        _gwt_print "$GREEN" "Current worktrees:"
        git worktree list
        return
    fi
    
    local branch="$1"
    # Sanitize branch name for directory (replace / with -)
    local safe_name
    safe_name=$(echo "$1" | tr '/' '-' | tr ' ' '-' | tr ':' '-')

    # Get base directory name from repository root
    local base_dir repo_root
    repo_root=$(git rev-parse --show-toplevel)
    base_dir=$(basename "$repo_root")

    # Construct target directory path using pattern
    local dir_name
    dir_name="${GWT_DIR_PATTERN//\{base\}/$base_dir}"
    dir_name="${dir_name//\{branch\}/$safe_name}"

    local target_dir="../${dir_name}"
    local abs_target
    abs_target=$(cd ..; pwd)/${dir_name}
    
    # Auto-prune if enabled
    if [[ "$GWT_AUTO_PRUNE" == "true" ]]; then
        git worktree prune 2>/dev/null
    fi
    
    # Check if worktree already exists
    if _gwt_get_worktree_paths | grep -Fxq "$abs_target"; then
        # Worktree exists, check if directory exists
        if [[ -d "$target_dir" ]]; then
            _gwt_print "$GREEN" "✓ Worktree already set up at $target_dir"
            cd "$target_dir" || return 1
            return
        else
            _gwt_print "$YELLOW" "⚠️  Worktree registered but directory missing. Repairing..."
            git worktree prune
        fi
    fi
    
    # Check if directory exists without worktree
    if [[ -d "$target_dir" ]]; then
        _gwt_print "$YELLOW" "⚠️  Directory exists without worktree: $target_dir"
        echo "Recent files:"
        ls -lt "$target_dir" 2>/dev/null | head -3
        
        if [[ "$GWT_CONFIRM_DELETE" == "true" ]]; then
            read -p "Delete and recreate? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                _gwt_print "$RED" "✗ Aborted"
                return 1
            fi
        fi
        
        rm -rf "$target_dir"
        _gwt_print "$GREEN" "✓ Removed old directory"
    fi
    
    # Determine if branch exists and create worktree accordingly
    local create_command=""

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        _gwt_print "$GREEN" "→ Using existing local branch: $branch"
        create_command="git worktree add '$target_dir' '$branch'"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        _gwt_print "$GREEN" "→ Checking out remote branch: origin/$branch"
        # Fetch to ensure we have latest remote and create tracking branch
        git fetch origin "$branch" 2>/dev/null
        create_command="git worktree add -b '$branch' '$target_dir' 'origin/$branch'"
    else
        _gwt_print "$GREEN" "→ Creating new branch: $branch"
        create_command="git worktree add -b '$branch' '$target_dir'"
    fi
    
    # Execute the worktree creation
    if eval "$create_command" 2>/dev/null; then
        cd "$target_dir" || return 1
        _gwt_print "$GREEN" "✓ Switched to $target_dir"
        
        # If submodules exist, initialize them
        if [[ -f .gitmodules ]]; then
            _gwt_print "$YELLOW" "→ Initializing submodules..."
            git submodule update --init --recursive
        fi
    else
        _gwt_print "$RED" "✗ Failed to create worktree"
        _gwt_print "$YELLOW" "Trying alternative approach..."
        
        # Try without -b flag first (in case branch exists somewhere)
        if git worktree add "$target_dir" "$branch" 2>/dev/null; then
            cd "$target_dir" || return 1
            _gwt_print "$GREEN" "✓ Switched to $target_dir"
        else
            _gwt_print "$RED" "✗ Could not create worktree for branch: $branch"
            return 1
        fi
    fi
}

# Cleanup function for orphaned directories and broken worktrees
wtclean() {
    _gwt_print "$GREEN" "=== Git Worktree Cleanup ==="
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _gwt_print "$RED" "✗ Not in a git repository"
        return 1
    fi
    
    # Prune broken worktree references
    _gwt_print "$YELLOW" "→ Pruning broken worktree references..."
    git worktree prune -v

    # Get base directory name from repository root
    local base_dir repo_root
    repo_root=$(git rev-parse --show-toplevel)
    base_dir=$(basename "$repo_root")
    
    # Find orphaned directories
    _gwt_print "$YELLOW" "→ Searching for orphaned directories..."
    
    local orphans=()
    local patterns
    # Convert space-separated patterns to array
    read -ra patterns <<< "$GWT_CLEANUP_PATTERNS"
    
    # Search for directories matching patterns
    for pattern in "${patterns[@]}"; do
        # Replace * with base directory in pattern if needed
        local search_pattern="${pattern/\*/${base_dir}}"
        
        # Use find to locate directories, handling spaces properly
        while IFS= read -r -d '' dir; do
            if [[ -d "$dir" ]]; then
                local abs_dir
                abs_dir=$(cd "$dir" 2>/dev/null && pwd)

                if [[ -n "$abs_dir" ]] && ! _gwt_get_worktree_paths | grep -Fxq "$abs_dir"; then
                    orphans+=("$dir")
                fi
            fi
        done < <(find .. -maxdepth 1 -type d -name "$search_pattern" -print0 2>/dev/null)
    done
    
    # Remove duplicates from orphans array
    local unique_orphans=()
    local seen=()
    for orphan in "${orphans[@]}"; do
        local skip=false
        for s in "${seen[@]}"; do
            if [[ "$s" == "$orphan" ]]; then
                skip=true
                break
            fi
        done
        if [[ "$skip" == false ]]; then
            seen+=("$orphan")
            unique_orphans+=("$orphan")
        fi
    done
    
    if [[ ${#unique_orphans[@]} -gt 0 ]]; then
        _gwt_print "$YELLOW" ""
        _gwt_print "$YELLOW" "Found ${#unique_orphans[@]} orphaned directories:"
        
        # Show disk usage for each orphan
        for orphan in "${unique_orphans[@]}"; do
            local size
            size=$(du -sh "$orphan" 2>/dev/null | cut -f1)
            echo "  $orphan (${size:-unknown size})"
        done
        
        if [[ "$GWT_CONFIRM_DELETE" == "true" ]]; then
            echo
            read -p "Delete all orphaned directories? (y/N) " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for orphan in "${unique_orphans[@]}"; do
                    rm -rf "$orphan"
                    _gwt_print "$GREEN" "  ✓ Removed $orphan"
                done
                _gwt_print "$GREEN" "✓ Cleaned up ${#unique_orphans[@]} directories"
            else
                _gwt_print "$YELLOW" "→ Skipped cleanup"
            fi
        else
            # Auto-delete if confirmation disabled
            for orphan in "${unique_orphans[@]}"; do
                rm -rf "$orphan"
            done
            _gwt_print "$GREEN" "✓ Cleaned up ${#unique_orphans[@]} directories"
        fi
    else
        _gwt_print "$GREEN" "✓ No orphaned directories found"
    fi
    
    # Show current active worktrees
    echo
    _gwt_print "$GREEN" "Active worktrees:"
    git worktree list
}

# List worktrees with additional information
wtlist() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _gwt_print "$RED" "✗ Not in a git repository"
        return 1
    fi
    
    _gwt_print "$GREEN" "=== Git Worktrees ==="
    
    # Get detailed worktree information
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local path branch
            path=$(echo "$line" | awk '{print $1}')
            branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')
            
            # Get last commit info if directory exists
            if [[ -d "$path" ]]; then
                local last_commit
                last_commit=$(cd "$path" && git log -1 --format="%h %s" 2>/dev/null || echo "no commits")
                local modified
                modified=$(cd "$path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
                
                echo "$path"
                echo "  Branch: $branch"
                echo "  Last commit: $last_commit"
                if [[ "$modified" -gt 0 ]]; then
                    _gwt_print "$YELLOW" "  Modified files: $modified"
                fi
            else
                echo "$path"
                _gwt_print "$RED" "  [MISSING DIRECTORY]"
            fi
            echo
        fi
    done < <(git worktree list)
}

# Quick switch between worktrees
wts() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _gwt_print "$RED" "✗ Not in a git repository"
        return 1
    fi
    
    # Get list of worktrees
    local worktrees=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            worktrees+=("$line")
        fi
    done < <(_gwt_get_worktree_paths)
    
    if [[ ${#worktrees[@]} -eq 0 ]]; then
        _gwt_print "$YELLOW" "No worktrees found"
        return 1
    fi
    
    # Display menu
    _gwt_print "$GREEN" "Select worktree to switch to:"
    local i=1
    for wt in "${worktrees[@]}"; do
        local current=""
        if [[ "$wt" == "$(pwd)" ]]; then
            current=" [CURRENT]"
            _gwt_print "$GREEN" "  $i) $wt$current"
        else
            echo "  $i) $wt$current"
        fi
        ((i++))
    done
    
    # Read selection
    echo
    read -p "Enter number (1-${#worktrees[@]}): " -r selection
    echo
    
    # Validate selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#worktrees[@]} ]]; then
        local target="${worktrees[$((selection-1))]}"
        cd "$target" || return 1
        _gwt_print "$GREEN" "✓ Switched to $target"
    else
        _gwt_print "$RED" "✗ Invalid selection"
        return 1
    fi
}

# Help function
wthelp() {
    cat << EOF
Git Worktree Utils - Command Reference

COMMANDS:
  wt [branch]      Create/switch to worktree for branch
  wt               List all worktrees (when called without arguments)
  wtclean          Clean up orphaned directories and broken worktrees
  wtlist           List worktrees with detailed information
  wts              Interactive worktree switcher
  wthelp           Show this help message

EXAMPLES:
  wt feature/new-thing     Create worktree for feature/new-thing branch
  wt hotfix/urgent        Create worktree for hotfix  
  wtclean                 Clean up broken worktrees

CONFIGURATION:
  Config file: ${XDG_CONFIG_HOME:-$HOME/.config}/git-worktree-utils/config
  
  GWT_AUTO_PRUNE          Auto-prune on every wt command (true/false)
  GWT_CONFIRM_DELETE      Confirm before deleting directories (true/false)
  GWT_CLEANUP_PATTERNS    Patterns for finding worktree directories

For more information: https://github.com/yourusername/git-worktree-utils
EOF
}

# Note: Functions are available after sourcing this script
# No export needed - they're sourced directly into the shell
