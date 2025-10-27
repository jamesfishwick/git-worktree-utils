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
wt() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        wthelp wt
        return
    fi

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
wtclean() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        wthelp wtclean
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
wtlist() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        wthelp wtlist
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
wts() {
    # Handle --help flag
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        wthelp wts
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

# Help function
wthelp() {
    local cmd="${1:-}"

    if [[ -n "$cmd" ]]; then
        case "$cmd" in
            wt)
                cat << 'EOF'
wt - Create and manage git worktrees

USAGE:
  wt                    List all worktrees
  wt <branch>           Create/switch to worktree for branch
  wt --help            Show this help

DESCRIPTION:
  The wt command intelligently manages git worktrees by creating sibling
  directories with standardized naming. It automatically handles:

  - New branches (creates them)
  - Local branches (checks them out)
  - Remote branches (fetches and tracks them)
  - Broken references (auto-prunes invalid worktrees)
  - Orphaned directories (warns and offers cleanup)
  - Submodules (initializes automatically)

DIRECTORY NAMING:
  By default, worktrees are created as sibling directories using the pattern:
    {base}-{branch}

  Example: If you're in /code/myapp and run "wt feature/auth", creates:
    /code/myapp-feature-auth/

  The pattern can be customized via GWT_DIR_PATTERN in the config file.

BRANCH DETECTION:
  wt automatically detects the branch type and handles it appropriately:

  1. Local branch exists → Uses existing branch
  2. Remote branch exists → Fetches and creates tracking branch
  3. Branch doesn't exist → Creates new branch from current HEAD

EXAMPLES:
  wt                           # List all worktrees
  wt feature/new-login        # Create worktree for new feature
  wt hotfix/security-patch    # Create worktree for hotfix
  wt colleague-branch         # Review colleague's work

  # From anywhere in the repository (auto-finds repo root):
  cd ~/code/myapp/src/components
  wt feature/refactor         # Still works! Creates ../myapp-feature-refactor

COMMON SCENARIOS:
  Emergency hotfix while working on feature:
    wt hotfix/urgent          # Instantly switch to clean hotfix environment
    # Fix, commit, push
    cd ../myapp-feature-xyz   # Return to feature work

  Code review:
    wt pr/review-123          # Check out PR in isolated directory
    # Test, review, comment
    wtclean                   # Remove when done

  Parallel development:
    wt approach-a             # Try solution A
    wt approach-b             # Try solution B
    diff -r ../myapp-approach-a ../myapp-approach-b  # Compare

SAFETY FEATURES:
  - Warns if directory exists without worktree
  - Shows recent files before deletion
  - Prompts for confirmation (configurable via GWT_CONFIRM_DELETE)
  - Auto-prunes broken worktree references (configurable via GWT_AUTO_PRUNE)

SEE ALSO:
  wtclean   Clean up orphaned directories
  wtlist    Detailed worktree information
  wts       Interactive worktree switcher
EOF
                ;;
            wtclean)
                cat << 'EOF'
wtclean - Clean up orphaned worktree directories

USAGE:
  wtclean
  wtclean --help

DESCRIPTION:
  Performs comprehensive cleanup of the worktree environment:

  1. Prunes broken worktree references from git
  2. Finds orphaned directories (directories that exist but have no worktree)
  3. Shows disk usage for each orphaned directory
  4. Offers to delete them (with confirmation)

WHAT IT FINDS:
  Orphaned directories are identified by matching patterns (configurable):
  - *-feature-*
  - *-hotfix-*
  - *-release-*
  - *-review-*
  - *-epic-*

  These patterns can be customized via GWT_CLEANUP_PATTERNS.

WHEN TO USE:
  - After merging branches and deleting remote branches
  - When worktree directories are manually moved/renamed
  - Before major refactoring to clean up workspace
  - Weekly maintenance to recover disk space
  - When "wt" warns about orphaned directories

EXAMPLES:
  wtclean                     # Interactive cleanup with confirmation

  # Typical output:
  # === Git Worktree Cleanup ===
  # → Pruning broken worktree references...
  # → Searching for orphaned directories...
  #
  # Found 3 orphaned directories:
  #   ../myapp-feature-old (458M)
  #   ../myapp-hotfix-merged (12M)
  #   ../myapp-review-pr-123 (234M)
  #
  # Delete all orphaned directories? (y/N)

SAFETY:
  - Always shows directory contents preview before deletion
  - Requires explicit confirmation (unless GWT_CONFIRM_DELETE=false)
  - Shows disk space that will be freed
  - Never deletes active worktrees

CONFIGURATION:
  GWT_CONFIRM_DELETE=false     # Skip confirmation prompts
  GWT_CLEANUP_PATTERNS="..."   # Custom directory patterns to find

SEE ALSO:
  wt        Create and manage worktrees
  wtlist    View detailed worktree information
EOF
                ;;
            wtlist)
                cat << 'EOF'
wtlist - List worktrees with detailed information

USAGE:
  wtlist
  wtlist --help

DESCRIPTION:
  Shows comprehensive information about all worktrees including:
  - Full directory path
  - Current branch name
  - Last commit (hash and message)
  - Number of modified files
  - Lock status (if locked)
  - Prunable status (if directory missing)

OUTPUT FORMAT:
  /path/to/worktree
    Branch: feature/branch-name
    Last commit: abc1234 Commit message here
    Modified files: 3
    [Locked]           # If worktree is locked
    [MISSING DIRECTORY] # If directory was deleted

EXAMPLES:
  wtlist

  # Typical output:
  # === Git Worktrees ===
  # /Users/dev/myapp
  #   Branch: main
  #   Last commit: a1b2c3d Initial commit
  #
  # /Users/dev/myapp-feature-auth
  #   Branch: feature/auth
  #   Last commit: d4e5f6g Add login form
  #   Modified files: 2

WHEN TO USE:
  - Get overview of all active development work
  - Check which worktrees have uncommitted changes
  - Find which worktree contains specific branch
  - Identify worktrees that need attention (missing directories, locked)

NOTES:
  - Requires being run from within a git repository
  - For simple list, use "wt" without arguments
  - For interactive switching, use "wts"

SEE ALSO:
  wt        Create and manage worktrees
  wts       Interactive worktree switcher
  wtclean   Clean up orphaned directories
EOF
                ;;
            wts)
                cat << 'EOF'
wts - Interactive worktree switcher

USAGE:
  wts
  wts --help

DESCRIPTION:
  Provides an interactive numbered menu to quickly switch between
  existing worktrees. Shows current worktree and allows selection
  by number.

EXAMPLES:
  wts

  # Typical session:
  # Select worktree to switch to:
  #   1) /Users/dev/myapp [CURRENT]
  #   2) /Users/dev/myapp-feature-auth
  #   3) /Users/dev/myapp-hotfix-urgent
  #
  # Enter number (1-3): 2
  # ✓ Switched to /Users/dev/myapp-feature-auth

WHEN TO USE:
  - Quick navigation between active worktrees
  - When you have many worktrees and don't want to type full names
  - Alternative to manual "cd ../worktree-name"

KEYBOARD:
  - Enter number and press Enter
  - Ctrl+C to cancel

NOTES:
  - Only shows currently valid worktrees
  - Highlights current worktree in list
  - Validates selection before switching

SEE ALSO:
  wt        Create new worktrees
  wtlist    View detailed worktree information
EOF
                ;;
            config)
                cat << 'EOF'
CONFIGURATION

CONFIG FILE LOCATION:
  ${XDG_CONFIG_HOME:-$HOME/.config}/git-worktree-utils/config

  Default: ~/.config/git-worktree-utils/config

AVAILABLE OPTIONS:

  GWT_DIR_PATTERN="{base}-{branch}"
    Controls how worktree directories are named.
    Variables:
      {base}   - Repository name (e.g., "myapp")
      {branch} - Sanitized branch name (e.g., "feature-auth")

    Examples:
      "{base}-{branch}"           → myapp-feature-auth
      "{branch}-{base}"           → feature-auth-myapp
      "wt-{base}-{branch}"        → wt-myapp-feature-auth
      "{base}/{branch}"           → myapp/feature-auth (nested)

  GWT_AUTO_PRUNE=true
    Automatically prune broken worktree references before each operation.
    Options: true | false
    Default: true

    When true: Silently cleans up broken references
    When false: You must manually run "git worktree prune"

  GWT_CONFIRM_DELETE=true
    Prompt for confirmation before deleting directories.
    Options: true | false
    Default: true

    When true: Shows preview and asks "Delete? (y/N)"
    When false: Automatically deletes without confirmation

  GWT_CLEANUP_PATTERNS="*-feature* *-hotfix* *-release* *-review* *-epic*"
    Space-separated patterns for directories that wtclean should find.
    Uses standard shell globbing patterns.

    Default patterns match:
      myapp-feature-*
      myapp-hotfix-*
      myapp-release-*
      myapp-review-*
      myapp-epic-*

    Customize for your workflow:
      GWT_CLEANUP_PATTERNS="*-feat-* *-fix-* *-wip-*"

  GWT_USE_COLOR=true
    Enable or disable colored output.
    Options: true | false
    Default: true

    When false: Plain text output (useful for scripting)

EXAMPLE CONFIG FILE:

  # Minimal config (uses mostly defaults)
  GWT_DIR_PATTERN="{base}-{branch}"
  GWT_AUTO_PRUNE=true

  # Paranoid config (confirmations for everything)
  GWT_CONFIRM_DELETE=true
  GWT_AUTO_PRUNE=false

  # Fast config (no confirmations)
  GWT_CONFIRM_DELETE=false
  GWT_AUTO_PRUNE=true

  # Custom naming (nested structure)
  GWT_DIR_PATTERN="worktrees/{base}/{branch}"
  GWT_CLEANUP_PATTERNS="worktrees/*"

CREATING CONFIG:

  # Copy example config
  mkdir -p ~/.config/git-worktree-utils
  cp config.example ~/.config/git-worktree-utils/config

  # Edit with your preferences
  $EDITOR ~/.config/git-worktree-utils/config

SEE ALSO:
  Example config in repository: config.example
EOF
                ;;
            *)
                _gwt_print "$RED" "Unknown help topic: $cmd"
                _gwt_print "$YELLOW" "Try: wthelp (for overview) or wthelp <command>"
                return 1
                ;;
        esac
    else
        # Main help overview
        cat << 'EOF'
Git Worktree Utils - Comprehensive Help

═══════════════════════════════════════════════════════════════════════════

QUICK START:
  wt                     List all worktrees
  wt feature/name        Create worktree for branch
  wtclean                Clean up old worktrees
  wthelp <command>       Detailed help for specific command

═══════════════════════════════════════════════════════════════════════════

CORE CONCEPT:

  Instead of switching branches, switch directories. Each worktree is a
  separate working directory with its own branch checked out.

  Traditional workflow:        Worktree workflow:
  /myapp (switch branches) →   /myapp              (main)
                               /myapp-feature-auth (feature)
                               /myapp-hotfix-bug   (hotfix)

═══════════════════════════════════════════════════════════════════════════

COMMANDS:

  wt [branch]
      Create or switch to a worktree for the specified branch.
      Without arguments, lists all worktrees.
      Run from anywhere in your repository.

      Examples:
        wt                      # List worktrees
        wt feature/auth         # Create worktree
        wt hotfix/urgent        # Emergency hotfix

      Details: wthelp wt

  wtclean
      Clean up orphaned directories and broken worktree references.
      Shows disk usage and prompts for confirmation.

      Examples:
        wtclean                 # Interactive cleanup

      Details: wthelp wtclean

  wtlist
      Show detailed information about all worktrees including branch,
      last commit, and modified file count.

      Examples:
        wtlist                  # Detailed worktree info

      Details: wthelp wtlist

  wts
      Interactive menu for quickly switching between worktrees.

      Examples:
        wts                     # Show numbered menu

      Details: wthelp wts

  wthelp [topic]
      Show help information.

      Examples:
        wthelp                  # This overview
        wthelp wt               # Detailed help for wt
        wthelp config           # Configuration reference

      Topics: wt, wtclean, wtlist, wts, config, workflows, examples

═══════════════════════════════════════════════════════════════════════════

COMMON WORKFLOWS:

  Feature Development:
    wt feature/new-feature      # Create isolated environment
    # ... work on feature ...
    git push origin feature/new-feature
    wtclean                     # Clean up after merge

  Emergency Hotfix:
    wt hotfix/critical          # Instant clean environment
    # ... fix bug ...
    git push
    cd ../myapp-feature-xyz     # Return to feature work

  Code Review:
    wt pr/review-123            # Check out PR
    # ... test and review ...
    cd ../myapp                 # Back to main work
    wtclean                     # Remove review worktree

  Parallel Approaches:
    wt approach-a               # Try solution A
    wt approach-b               # Try solution B
    diff -r ../myapp-approach-a ../myapp-approach-b
    # Keep the better one, wtclean the other

═══════════════════════════════════════════════════════════════════════════

CONFIGURATION:

  Config file: ${XDG_CONFIG_HOME:-$HOME/.config}/git-worktree-utils/config

  Quick reference:
    GWT_DIR_PATTERN           Directory naming pattern
    GWT_AUTO_PRUNE           Auto-prune broken references
    GWT_CONFIRM_DELETE       Prompt before deletion
    GWT_CLEANUP_PATTERNS     Patterns for finding orphans
    GWT_USE_COLOR            Enable colored output

  Full details: wthelp config

═══════════════════════════════════════════════════════════════════════════

GETTING HELP:

  General help:        wthelp
  Command details:     wthelp <command>
  Configuration:       wthelp config
  Workflows:           wthelp workflows
  Examples:            wthelp examples

  Available topics:
    - wt          Main worktree command
    - wtclean     Cleanup utility
    - wtlist      Detailed listing
    - wts         Interactive switcher
    - config      Configuration reference
    - workflows   Common usage patterns
    - examples    Real-world examples

═══════════════════════════════════════════════════════════════════════════

TROUBLESHOOTING:

  "Directory already exists":
    wtclean                       # Will detect and offer removal

  "Branch already exists":
    wt existing-branch           # Just checks it out

  Worktree in broken state:
    git worktree prune
    wtclean

  After moving repository:
    git worktree repair

═══════════════════════════════════════════════════════════════════════════

For detailed help on any command: wthelp <command>
GitHub: https://github.com/yourusername/git-worktree-utils

EOF
    fi
}

# Note: Functions are available after sourcing this script
# No export needed - they're sourced directly into the shell
