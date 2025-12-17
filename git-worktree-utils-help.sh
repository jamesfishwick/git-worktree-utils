#!/usr/bin/env bash
# Git Worktree Utils - Help Documentation
# Sourced by git-worktree-utils.sh

# Help function
gwthelp() {
    local cmd="${1:-}"

    if [[ -n "$cmd" ]]; then
        case "$cmd" in
            gwt)
                cat << 'EOF'
gwt - Create and manage git worktrees

USAGE:
  gwt                    List all worktrees
  gwt <branch>           Create/switch to worktree for branch
  gwt --help            Show this help

DESCRIPTION:
  The gwt command intelligently manages git worktrees by creating sibling
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

  Example: If you're in /code/myapp and run "gwt feature/auth", creates:
    /code/myapp-feature-auth/

  The pattern can be customized via GWT_DIR_PATTERN in the config file.

BRANCH DETECTION:
  gwt automatically detects the branch type and handles it appropriately:

  1. Local branch exists → Uses existing branch
  2. Remote branch exists → Fetches and creates tracking branch
  3. Branch doesn't exist → Creates new branch from current HEAD

EXAMPLES:
  gwt                           # List all worktrees
  gwt feature/new-login        # Create worktree for new feature
  gwt hotfix/security-patch    # Create worktree for hotfix
  gwt colleague-branch         # Review colleague's work

  # From anywhere in the repository (auto-finds repo root):
  cd ~/code/myapp/src/components
  gwt feature/refactor         # Still works! Creates ../myapp-feature-refactor

COMMON SCENARIOS:
  Emergency hotfix while working on feature:
    gwt hotfix/urgent          # Instantly switch to clean hotfix environment
    # Fix, commit, push
    cd ../myapp-feature-xyz   # Return to feature work

  Code review:
    gwt pr/review-123          # Check out PR in isolated directory
    # Test, review, comment
    gwtclean                   # Remove when done

  Parallel development:
    gwt approach-a             # Try solution A
    gwt approach-b             # Try solution B
    diff -r ../myapp-approach-a ../myapp-approach-b  # Compare

SAFETY FEATURES:
  - Warns if directory exists without worktree
  - Shows recent files before deletion
  - Prompts for confirmation (configurable via GWT_CONFIRM_DELETE)
  - Auto-prunes broken worktree references (configurable via GWT_AUTO_PRUNE)

SEE ALSO:
  gwtclean   Clean up orphaned directories
  gwtlist    Detailed worktree information
  gwts       Interactive worktree switcher
EOF
                ;;
            gwtclean)
                cat << 'EOF'
gwtclean - Clean up orphaned worktree directories

USAGE:
  gwtclean
  gwtclean --help

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
  - When "gwt" warns about orphaned directories

EXAMPLES:
  gwtclean                     # Interactive cleanup with confirmation

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
  gwt        Create and manage worktrees
  gwtlist    View detailed worktree information
EOF
                ;;
            gwtlist)
                cat << 'EOF'
gwtlist - List worktrees with detailed information

USAGE:
  gwtlist
  gwtlist --help

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
  gwtlist

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
  - For simple list, use "gwt" without arguments
  - For interactive switching, use "gwts"

SEE ALSO:
  gwt        Create and manage worktrees
  gwts       Interactive worktree switcher
  gwtclean   Clean up orphaned directories
EOF
                ;;
            gwts)
                cat << 'EOF'
gwts - Interactive worktree switcher

USAGE:
  gwts
  gwts --help

DESCRIPTION:
  Provides an interactive numbered menu to quickly switch between
  existing worktrees. Shows current worktree and allows selection
  by number.

EXAMPLES:
  gwts

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
  gwt        Create new worktrees
  gwtlist    View detailed worktree information
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
      "gwt-{base}-{branch}"        → gwt-myapp-feature-auth
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
    Space-separated patterns for directories that gwtclean should find.
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
                _gwt_print "$YELLOW" "Try: gwthelp (for overview) or gwthelp <command>"
                return 1
                ;;
        esac
    else
        # Main help overview
        cat << 'EOF'
Git Worktree Utils - Comprehensive Help

═══════════════════════════════════════════════════════════════════════════

QUICK START:
  gwt                     List all worktrees
  gwt feature/name        Create worktree for branch
  gwtclean                Clean up old worktrees
  gwthelp <command>       Detailed help for specific command

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

  gwt [branch]
      Create or switch to a worktree for the specified branch.
      Without arguments, lists all worktrees.
      Run from anywhere in your repository.

      Examples:
        gwt                      # List worktrees
        gwt feature/auth         # Create worktree
        gwt hotfix/urgent        # Emergency hotfix

      Details: gwthelp gwt

  gwtclean
      Clean up orphaned directories and broken worktree references.
      Shows disk usage and prompts for confirmation.

      Examples:
        gwtclean                 # Interactive cleanup

      Details: gwthelp gwtclean

  gwtlist
      Show detailed information about all worktrees including branch,
      last commit, and modified file count.

      Examples:
        gwtlist                  # Detailed worktree info

      Details: gwthelp gwtlist

  gwts
      Interactive menu for quickly switching between worktrees.

      Examples:
        gwts                     # Show numbered menu

      Details: gwthelp gwts

  gwthelp [topic]
      Show help information.

      Examples:
        gwthelp                  # This overview
        gwthelp gwt               # Detailed help for gwt
        gwthelp config           # Configuration reference

      Topics: gwt, gwtclean, gwtlist, gwts, config, workflows, examples

═══════════════════════════════════════════════════════════════════════════

COMMON WORKFLOWS:

  Feature Development:
    gwt feature/new-feature      # Create isolated environment
    # ... work on feature ...
    git push origin feature/new-feature
    gwtclean                     # Clean up after merge

  Emergency Hotfix:
    gwt hotfix/critical          # Instant clean environment
    # ... fix bug ...
    git push
    cd ../myapp-feature-xyz     # Return to feature work

  Code Review:
    gwt pr/review-123            # Check out PR
    # ... test and review ...
    cd ../myapp                 # Back to main work
    gwtclean                     # Remove review worktree

  Parallel Approaches:
    gwt approach-a               # Try solution A
    gwt approach-b               # Try solution B
    diff -r ../myapp-approach-a ../myapp-approach-b
    # Keep the better one, gwtclean the other

═══════════════════════════════════════════════════════════════════════════

CONFIGURATION:

  Config file: ${XDG_CONFIG_HOME:-$HOME/.config}/git-worktree-utils/config

  Quick reference:
    GWT_DIR_PATTERN           Directory naming pattern
    GWT_AUTO_PRUNE           Auto-prune broken references
    GWT_CONFIRM_DELETE       Prompt before deletion
    GWT_CLEANUP_PATTERNS     Patterns for finding orphans
    GWT_USE_COLOR            Enable colored output

  Full details: gwthelp config

═══════════════════════════════════════════════════════════════════════════

GETTING HELP:

  General help:        gwthelp
  Command details:     gwthelp <command>
  Configuration:       gwthelp config
  Workflows:           gwthelp workflows
  Examples:            gwthelp examples

  Available topics:
    - gwt          Main worktree command
    - gwtclean     Cleanup utility
    - gwtlist      Detailed listing
    - gwts         Interactive switcher
    - config      Configuration reference
    - workflows   Common usage patterns
    - examples    Real-world examples

═══════════════════════════════════════════════════════════════════════════

TROUBLESHOOTING:

  "Directory already exists":
    gwtclean                       # Will detect and offer removal

  "Branch already exists":
    gwt existing-branch           # Just checks it out

  Worktree in broken state:
    git worktree prune
    gwtclean

  After moving repository:
    git worktree repair

═══════════════════════════════════════════════════════════════════════════

For detailed help on any command: gwthelp <command>
GitHub: https://github.com/yourusername/git-worktree-utils

EOF
    fi
}
