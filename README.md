# Git Worktree Utils

> **Lightweight, zero-install git worktree manager for bash enthusiasts**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

Simple, shell-native utilities for managing git worktrees. Switch between branches by switching directories—no dependencies, no installation hassle, just source and go.

**Perfect for:** Dotfile minimalists, bash power users, and developers who value simplicity over features.

## Why Worktrees?

Traditional git workflow requires constant branch switching in a single directory. Git worktrees let you have multiple branches checked out simultaneously in separate directories:

```
Traditional:                  With Worktrees:
/myapp (switch branches) →    /myapp              (main)
                              /myapp-feature-auth (feature)
                              /myapp-hotfix-bug   (hotfix)
```

**Benefits:**

- No stashing needed when switching contexts
- Multiple branches tested simultaneously
- IDE state preserved per branch
- Clean separation of work contexts

## Why git-worktree-utils?

**vs. Branchyard:** If you want VS Code integration, git hooks, and a feature-rich CLI, use [Branchyard](https://github.com/SivaramPg/branchyard)—it's excellent.

**Choose git-worktree-utils if you value:**

- **Lightweight** - Single bash script (988 lines), zero dependencies
- **Dotfile-friendly** - Source-based, not installed binary
- **Shell-native** - Built for bash/zsh power users
- **Simple** - No build step, no package manager, no runtime
- **XDG-compliant** - Respects your config directory standards

**Philosophy:** Solve one problem well. Make git worktrees easy from the command line. Nothing more.

## Installation

### Automated Install (Recommended)

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash

# Or download and inspect first
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

The installer will:

- Download scripts to `~/.config/git-worktree-utils/`
- Offer to add source line to your shell config
- Provide example configuration

### Manual Install

```bash
# Create directory
mkdir -p ~/.config/git-worktree-utils

# Download main script
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/git-worktree-utils.sh \
  -o ~/.config/git-worktree-utils/git-worktree-utils.sh

# Source in your shell config (~/.bashrc or ~/.zshrc)
echo 'source ~/.config/git-worktree-utils/git-worktree-utils.sh' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

### Dotfile Integration

Already manage dotfiles? Just add `git-worktree-utils.sh` to your dotfiles and source it:

```bash
# In your dotfiles repo
git-worktree-utils/git-worktree-utils.sh

# In your ~/.bashrc or ~/.zshrc
source ~/dotfiles/git-worktree-utils/git-worktree-utils.sh
```

## Quick Start

```bash
# List existing worktrees
gwt

# Create/switch to worktree for branch
gwt feature/new-login

# List detailed worktree info
gwtlist

# Clean up orphaned directories
gwtclean

# Interactive worktree switcher
gwts

# Get help
gwthelp
gwthelp gwt        # Detailed help for specific command
```

## Commands

### `gwt [branch]`

Create or switch to a worktree for the specified branch.

**Without arguments**: Lists all worktrees
**With branch name**: Creates/switches to worktree directory

```bash
gwt                          # List worktrees
gwt feature/auth             # Create worktree for feature/auth
gwt hotfix/security-patch    # Emergency hotfix in clean environment
```

**Behavior:**

- Automatically creates sibling directories with pattern `{base}-{branch}`
- Handles local branches, remote branches, and new branches intelligently
- Auto-initializes submodules if present
- Prunes broken worktree references (configurable)
- Warns about orphaned directories with cleanup options

### `gwtlist`

Display detailed information about all worktrees including branch, last commit, and modified file count.

```bash
gwtlist

# Example output:
# === Git Worktrees ===
# /Users/dev/myapp
#   Branch: main
#   Last commit: a1b2c3d Initial commit
#
# /Users/dev/myapp-feature-auth
#   Branch: feature/auth
#   Last commit: d4e5f6g Add login form
#   Modified files: 2
```

### `gwtclean`

Clean up orphaned directories and broken worktree references.

```bash
gwtclean

# Interactive cleanup with disk usage display:
# === Git Worktree Cleanup ===
# → Pruning broken worktree references...
# → Searching for orphaned directories...
#
# Found 3 orphaned directories:
#   ../myapp-feature-old (458M)
#   ../myapp-hotfix-merged (12M)
#
# Delete all orphaned directories? (y/N)
```

### `gwts`

Interactive numbered menu for quickly switching between worktrees.

```bash
gwts

# Select worktree to switch to:
#   1) /Users/dev/myapp [CURRENT]
#   2) /Users/dev/myapp-feature-auth
#   3) /Users/dev/myapp-hotfix-urgent
#
# Enter number (1-3): 2
# ✓ Switched to /Users/dev/myapp-feature-auth
```

### `gwthelp [topic]`

Display comprehensive help information.

```bash
gwthelp              # General overview
gwthelp gwt           # Detailed help for wt command
gwthelp config       # Configuration reference
gwthelp workflows    # Common workflow examples
```

## Configuration

Configuration file: `${XDG_CONFIG_HOME:-$HOME/.config}/git-worktree-utils/config`

### Available Options

```bash
# Directory naming pattern
GWT_DIR_PATTERN="{base}-{branch}"
# Variables: {base} = repo name, {branch} = sanitized branch name

# Automatically prune broken worktree references
GWT_AUTO_PRUNE=true

# Prompt for confirmation before deleting directories
GWT_CONFIRM_DELETE=true

# Patterns for directories that gwtclean should find
GWT_CLEANUP_PATTERNS="*-feature* *-hotfix* *-release* *-review* *-epic*"

# Enable colored output
GWT_USE_COLOR=true
```

### Example Configurations

**Minimal (recommended)**

```bash
GWT_DIR_PATTERN="{base}-{branch}"
GWT_AUTO_PRUNE=true
```

**Fast (no confirmations)**

```bash
GWT_CONFIRM_DELETE=false
GWT_AUTO_PRUNE=true
```

**Nested structure**

```bash
GWT_DIR_PATTERN="worktrees/{base}/{branch}"
GWT_CLEANUP_PATTERNS="worktrees/*"
```

## Common Workflows

### Feature Development

```bash
# Start new feature
gwt feature/user-profile

# Work on feature...
# Commit, push when ready
git push origin feature/user-profile

# Create PR, merge, then cleanup
cd ../myapp  # Back to main
gwtclean      # Remove feature worktree
```

### Emergency Hotfix

```bash
# Currently working on feature branch
# Emergency bug reported!

gwt hotfix/critical-security-fix  # Instant clean environment
# Fix bug, commit, push
git push origin hotfix/critical-security-fix

# Return to feature work
cd ../myapp-feature-xyz
# Feature work preserved exactly as you left it
```

### Code Review

```bash
# Review colleague's PR
gwt pr/review-123

# Run tests, make comments, test locally
npm test
# Review code...

# Done reviewing
cd ../myapp
gwtclean  # Remove review worktree
```

### Parallel Approaches

```bash
# Try two different solutions
gwt experiment/approach-a
# Implement solution A...

gwt experiment/approach-b
# Implement solution B...

# Compare implementations
diff -r ../myapp-experiment-approach-a ../myapp-experiment-approach-b

# Keep the better one, cleanup the other
gwtclean
```

## Architecture

### Code Structure

- **Helper Functions** (`_gwt_*`): Internal utilities with `_gwt_` prefix
  - `_gwt_print`: Colored output formatting
  - `_gwt_get_worktree_paths`: Parse worktree paths from porcelain output
  - `_gwt_list_recent`: Platform-aware recent file listing
  - `_gwt_display_worktree_info`: Comprehensive worktree information display

- **Main Commands** (`wt*`): User-facing functions
  - `wt`: Core worktree creation/switching
  - `gwtlist`: Detailed worktree listing
  - `gwtclean`: Cleanup utility
  - `gwts`: Interactive switcher
  - `gwthelp`: Help system

### Design Principles

- **DRY**: Code duplication eliminated through helper functions
- **Robustness**: Handles spaces in paths, uses porcelain format for parsing
- **Safety**: Confirms destructive operations, shows previews before deletion
- **Platform Compatibility**: Cross-platform support (macOS, Linux, BSD fallback)
- **User Experience**: Colored output, clear error messages, comprehensive help

## Troubleshooting

### "Directory already exists"

```bash
gwtclean  # Will detect and offer removal
```

### "Branch already exists"

```bash
gwt existing-branch  # Just checks it out
```

### Worktree in broken state

```bash
git worktree prune
gwtclean
```

### After moving repository

```bash
git worktree repair
```

## Contributing

Contributions welcome! This project prioritizes:

- **Simplicity** - Keep it lightweight and bash-native
- **Compatibility** - Support macOS, Linux, BSD
- **Zero dependencies** - Bash + git only
- **XDG compliance** - Respect user config standards

Feel free to open issues or submit PRs at [github.com/jamesfishwick/git-worktree-utils](https://github.com/jamesfishwick/git-worktree-utils).

## License

[MIT License](LICENSE) - Use freely, modify as needed.

Copyright © 2025 [James Fishwick](https://github.com/jamesfishwick)

## Credits

Built on git's native worktree functionality with quality-of-life improvements for daily development workflows. Inspired by the need for simple, dotfile-friendly tooling.
