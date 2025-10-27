# Git Worktree Utils - Project Overview

## Purpose
Shell utility tools for smart git worktree management, enabling parallel development workflows through automatic directory management, state reconciliation, and safety-first operations.

## Core Components
1. **git-worktree-utils.sh** - Main worktree functions (`wt` and `wtclean`)
2. **install.sh** - Automated installation script
3. **uninstall.sh** - Clean removal script
4. **test.sh** - Test suite

## Key Features
- Automatic sibling directory creation with branch-based naming
- State reconciliation for orphaned directories and broken worktree references
- Smart branch detection (new, local, remote branches)
- Safety prompts before destructive operations
- Disk usage reporting during cleanup

## Technical Stack
- **Language**: Bash/Zsh shell scripting
- **Dependencies**: Git, standard Unix tools only
- **Installation**: `~/.config/git-worktree-utils/`
- **Configuration**: `~/.config/git-worktree-utils/config`

## Workflow Philosophy
"Stop switching branches. Start switching directories."
- Each branch gets its own directory
- Multiple branches checked out simultaneously
- No context switching overhead
- Ideal for parallel development, code reviews, and emergency hotfixes

## Directory Structure Pattern
`{base}-{branch}` format creates sibling directories:
- `myapp/` (main repository)
- `myapp-feature-payment/` (feature worktree)
- `myapp-hotfix-urgent/` (hotfix worktree)

## Current Status
- README documentation complete with comprehensive examples
- Not currently a git repository (working directory for documentation updates)
- Shell scripts present: core functionality, installation, testing, uninstallation
