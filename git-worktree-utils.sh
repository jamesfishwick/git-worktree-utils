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

# Color codes for output (can be disabled via GWT_USE_COLOR)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to print colored output
_gwt_print() {
    local color=$1
    shift
    if [[ "${GWT_USE_COLOR:-true}" != "true" ]]; then
        printf '%s\n' "$*"
    else
        printf '%b\n' "${color}$*${NC}"
    fi
}

# Helper function to parse worktree paths from --porcelain output
_gwt_get_worktree_paths() {
    git worktree list --porcelain | awk '/^worktree / {print $2}'
}

# Helper: list recent entries in a directory (by mtime)
_gwt_list_recent() {
    local dir="$1"
    local n="${2:-3}"

    case "$(uname -s)" in
        Darwin)
            while IFS= read -r -d '' p; do
                stat -f "%m %N" "$p" 2>/dev/null || true
            done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null) \
            | sort -nr | head -n "$n" | cut -d' ' -f2- | sed 's/^/  /'
            ;;
        Linux)
            while IFS= read -r -d '' p; do
                stat -c "%Y %n" "$p" 2>/dev/null || true
            done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null) \
            | sort -nr | head -n "$n" | cut -d' ' -f2- | sed 's/^/  /'
            ;;
        *)
            # Fallback: unsorted list via find (no ls parsing)
            find "$dir" -mindepth 1 -maxdepth 1 -print 2>/dev/null | head -n "$n" | sed 's/^/  /'
            ;;
    esac
}

# Main worktree function
gwt() {
    # Handle --help flag first, before any other checks
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        gwthelp gwt
        return 0
    fi

    # If no argument, list worktrees (doesn't require git repo check if we just want to show nothing)
    if [[ -z "$1" ]]; then
        # Check if we're in a git repository
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            _gwt_print "$RED" "✗ Not in a git repository"
            return 1
        fi
        _gwt_print "$GREEN" "Current worktrees:"
        git worktree list
        return 0
    fi

    # Check if we're in a git repository for branch operations
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _gwt_print "$RED" "✗ Not in a git repository"
        return 1
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
        echo "Recent entries:"
        _gwt_list_recent "$target_dir" 3
        
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
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        _gwt_print "$GREEN" "→ Using existing local branch: $branch"
        if git worktree add "$target_dir" "$branch" 2>/dev/null; then
            cd "$target_dir" || return 1
            _gwt_print "$GREEN" "✓ Switched to $target_dir"
            
            # If submodules exist, initialize them
            if [[ -f .gitmodules ]]; then
                _gwt_print "$YELLOW" "→ Initializing submodules..."
                git submodule update --init --recursive
            fi
            return
        fi
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        _gwt_print "$GREEN" "→ Checking out remote branch: origin/$branch"
        git fetch origin "$branch" 2>/dev/null
        if git worktree add -b "$branch" "$target_dir" "origin/$branch" 2>/dev/null; then
            cd "$target_dir" || return 1
            _gwt_print "$GREEN" "✓ Switched to $target_dir"
            if [[ -f .gitmodules ]]; then
                _gwt_print "$YELLOW" "→ Initializing submodules..."
                git submodule update --init --recursive
            fi
            return
        fi
    else
        _gwt_print "$GREEN" "→ Creating new branch: $branch"
        if git worktree add -b "$branch" "$target_dir" 2>/dev/null; then
            cd "$target_dir" || return 1
            _gwt_print "$GREEN" "✓ Switched to $target_dir"
            if [[ -f .gitmodules ]]; then
                _gwt_print "$YELLOW" "→ Initializing submodules..."
                git submodule update --init --recursive
            fi
            return
        fi
    fi

    # If we reached here, primary path failed; try alternative approach
    _gwt_print "$RED" "✗ Failed to create worktree"
    _gwt_print "$YELLOW" "Trying alternative approach..."
    if git worktree add "$target_dir" "$branch" 2>/dev/null; then
        cd "$target_dir" || return 1
        _gwt_print "$GREEN" "✓ Switched to $target_dir"
    else
        _gwt_print "$RED" "✗ Could not create worktree for branch: $branch"
        return 1
    fi
}

# Cleanup function for orphaned directories and broken worktrees
gwtclean() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        gwthelp gwtclean
        return
    fi

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
gwtlist() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        gwthelp gwtlist
        return
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        _gwt_print "$RED" "✗ Not in a git repository"
        return 1
    fi
    
    _gwt_print "$GREEN" "=== Git Worktrees ==="
    
    # Parse porcelain output to handle spaces/newlines robustly
    local path="" branch="" locked="" prunable=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "$line" ]]; then
            if [[ -n "$path" ]]; then
                if [[ -d "$path" ]]; then
                    local last_commit modified
                    last_commit=$(cd "$path" && git log -1 --format="%h %s" 2>/dev/null || echo "no commits")
                    modified=$(cd "$path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
                    echo "$path"
                    if [[ -n "$branch" ]]; then
                        echo "  Branch: $branch"
                    else
                        echo "  Branch: (detached)"
                    fi
                    echo "  Last commit: $last_commit"
                    if [[ "$modified" -gt 0 ]]; then
                        _gwt_print "$YELLOW" "  Modified files: $modified"
                    fi
                    if [[ -n "$locked" ]]; then
                        _gwt_print "$YELLOW" "  Locked"
                    fi
                    if [[ -n "$prunable" ]]; then
                        _gwt_print "$YELLOW" "  Prunable"
                    fi
                else
                    echo "$path"
                    _gwt_print "$RED" "  [MISSING DIRECTORY]"
                fi
                echo
            fi
            path=""; branch=""; locked=""; prunable=""
            continue
        fi
        case "$line" in
            worktree\ *)
                path=${line#worktree }
                ;;
            branch\ *)
                branch=${line#branch }
                if [[ "$branch" == refs/heads/* ]]; then
                    branch=${branch#refs/heads/}
                elif [[ "$branch" == refs/remotes/* ]]; then
                    branch=${branch##*/}
                fi
                ;;
            locked*)
                locked=1
                ;;
            prunable*)
                prunable=1
                ;;
        esac
    done < <(git worktree list --porcelain)
    
    # Flush last block if not already
    if [[ -n "$path" ]]; then
        if [[ -d "$path" ]]; then
            local last_commit modified
            last_commit=$(cd "$path" && git log -1 --format="%h %s" 2>/dev/null || echo "no commits")
            modified=$(cd "$path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            echo "$path"
            if [[ -n "$branch" ]]; then
                echo "  Branch: $branch"
            else
                echo "  Branch: (detached)"
            fi
            echo "  Last commit: $last_commit"
            if [[ "$modified" -gt 0 ]]; then
                _gwt_print "$YELLOW" "  Modified files: $modified"
            fi
            if [[ -n "$locked" ]]; then
                _gwt_print "$YELLOW" "  Locked"
            fi
            if [[ -n "$prunable" ]]; then
                _gwt_print "$YELLOW" "  Prunable"
            fi
        else
            echo "$path"
            _gwt_print "$RED" "  [MISSING DIRECTORY]"
        fi
        echo
    fi
}

# Quick switch between worktrees
gwts() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        gwthelp gwts
        return
    fi

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

# Load help functions from separate file
_GWT_SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
if [[ -f "${_GWT_SCRIPT_DIR}/git-worktree-utils-help.sh" ]]; then
    # shellcheck source=git-worktree-utils-help.sh
    source "${_GWT_SCRIPT_DIR}/git-worktree-utils-help.sh"
fi
