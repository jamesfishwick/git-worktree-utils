#!/usr/bin/env bash
# Git Worktree Utils - Help Documentation
# Sourced by git-worktree-utils.sh

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
