# Git Worktree Utils

> Smart git worktree management for parallel development workflows

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: Bash/Zsh](https://img.shields.io/badge/Shell-Bash%2FZsh-green.svg)](https://www.gnu.org/software/bash/)

## Why This Exists

Git worktrees let you check out multiple branches simultaneously in different directories. This tool makes that workflow seamless by:

- **Automatic directory management** - Creates sibling directories with branch-based naming
- **State reconciliation** - Handles orphaned directories and broken worktree references
- **Smart branch detection** - Works with new, local, and remote branches automatically
- **Safety first** - Prompts before destructive operations, shows what will be deleted

## Quick Start

```bash
# Clone and install manually
git clone https://github.com/yourusername/git-worktree-utils.git
cd git-worktree-utils
./install.sh

# Basic usage (run from anywhere in your git repository)
wt                      # List all worktrees
wt feature/payment      # Create worktree for branch
wtclean                 # Clean up orphaned directories

# Get comprehensive help
wthelp                  # Help overview with examples
wthelp wt               # Detailed help for specific command
wt --help               # Alternative syntax (same as above)
```

**Note**: Commands can be run from any directory within your git repository. The tool automatically determines the repository root.

**Need help?** Start with `wthelp` for a comprehensive guide including examples, workflows, and configuration options.

## The Mental Model

Stop switching branches. Start switching directories.

```
Traditional:                    With Worktrees:
/myproject                      /myproject         (main)
  └── switches between →        /myproject-feature (feature branch)
      - main                    /myproject-hotfix  (hotfix branch)
      - feature
      - hotfix
```

## Core Commands

### `wt` - Worktree Management

```bash
# List all worktrees
wt

# Create/switch to worktree for a branch
wt feature/new-thing

# Get help
wt --help

# Creates: ../myproject-feature-new-thing/
# Switches to that directory automatically
```

**Smart branch handling:**
- Creates new branch if it doesn't exist
- Uses existing local branch if found
- Checks out remote branch if available

**Safety features:**
- Auto-prunes broken references
- Detects orphaned directories
- Prompts before overwriting existing directories

### `wtclean` - Cleanup Utility

```bash
# Full cleanup of broken worktrees
wtclean

# Get help
wtclean --help

# What it does:
# 1. Prunes invalid worktree references
# 2. Finds orphaned directories
# 3. Shows disk usage for each
# 4. Offers to delete with confirmation
```

## Real-World Workflow

**Tip**: Run `wt` commands from anywhere in your repository - the tool automatically finds the repo root.

```bash
# Morning: Working on feature
cd ~/code/myapp
wt feature/user-auth
# Creates ~/code/myapp-feature-user-auth/
# You're now in that directory, coding...

# Emergency: Production bug!
wt hotfix/critical-issue
# Creates ~/code/myapp-hotfix-critical-issue/
# Fix the bug, push, create PR

# Back to feature (just cd, everything still there)
cd ../myapp-feature-user-auth
# Continue exactly where you left off

# Review a colleague's PR
wt feature/colleague-branch
# Test their changes without affecting your work

# Cleanup after merging
wtclean
# Remove old worktree directories
```

## Directory Structure

The tool creates sibling directories based on your current repo name:

```
~/code/
├── myapp/                    # Main repository (main branch)
├── myapp-feature-payment/    # Feature branch worktree
├── myapp-hotfix-urgent/       # Hotfix branch worktree
└── myapp-review-pr-123/      # Code review worktree
```

## Installation

### Manual Installation

**Note**: Replace `yourusername` with the actual GitHub username/organization where this repository is hosted.

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/git-worktree-utils.git
   cd git-worktree-utils
   ```

2. Run the installer:
   ```bash
   ./install.sh
   ```

3. Restart your shell or source your config:
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

### What Gets Installed

- `${XDG_CONFIG_HOME:-~/.config}/git-worktree-utils/` - Configuration directory and script
- Shell functions added to your `.zshrc`/`.bashrc`
- No dependencies required (uses only git and standard Unix tools)

## Configuration

Configuration file: `${XDG_CONFIG_HOME:-~/.config}/git-worktree-utils/config`

```bash
# Directory naming pattern
GWT_DIR_PATTERN="{base}-{branch}"  # Default: myapp-feature-name

# Auto-prune on every wt command
GWT_AUTO_PRUNE=true

# Prompt before destructive operations
GWT_CONFIRM_DELETE=true

# Directory search patterns for cleanup
GWT_CLEANUP_PATTERNS="*-feature* *-hotfix* *-release* *-review*"
```

## Common Patterns

### Dedicated Purpose Directories

```bash
# Set up standard directories
wt main                # ../myapp-main/
wt develop             # ../myapp-develop/
wt staging             # ../myapp-staging/

# Then for features
wt feature/thing       # ../myapp-feature-thing/
```

### Long-Running Features

```bash
# Multi-week epic
wt epic/big-refactor

# Daily work happens here
cd ../myapp-epic-big-refactor

# Main stays clean for comparisons
diff -r . ../myapp/
```

### Review Workflow

```bash
# Dedicated review directory
mkdir ../reviews

# Review function (add to your shell config)
review() {
    cd ../reviews
    git worktree add "./pr-$1" "origin/pr/$1"
    cd "./pr-$1"
}

# Usage
review 423  # Reviews PR #423
```

## Troubleshooting

### "Fatal: directory already exists"

```bash
# Directory exists without worktree
wtclean  # Will detect and offer to remove
```

### "Fatal: branch already exists"

```bash
# You're trying to create a branch that exists
wt existing-branch  # Just check it out instead
```

### Worktree in inconsistent state

```bash
# Nuclear option - manual cleanup
git worktree prune
git worktree list
rm -rf ../myapp-broken-directory
```

### Moving repositories

```bash
# After moving repo to new location
git worktree repair
```

## Advanced Usage

### Custom Directory Names

```bash
# Override automatic naming
git worktree add ../custom-name feature/branch
cd ../custom-name
```

### Worktrees for Different Remotes

```bash
# Add upstream remote
git remote add upstream https://github.com/original/repo.git

# Worktree for upstream branch
git fetch upstream
git worktree add ../myapp-upstream upstream/main
```

### Comparison Workflows

```bash
# Side-by-side implementation comparison
wt approach-1
# Implement solution A

wt approach-2  
# Implement solution B

# Compare
diff -r ../myapp-approach-1 ../myapp-approach-2
```

## Best Practices

1. **One worktree per feature** - Don't reuse worktrees for different features
2. **Clean up regularly** - Run `wtclean` weekly
3. **Use descriptive branch names** - They become directory names
4. **Keep main clean** - Never develop directly in the main worktree
5. **Document worktree purpose** - Add README in long-lived worktrees

## Performance Notes

- Each worktree is a full working directory (minus .git)
- Large repositories = significant disk usage per worktree
- Consider `git sparse-checkout` for monorepos
- SSDs recommended for large projects with many worktrees

## Limitations

- Cannot check out same branch in multiple worktrees
- Submodules require initialization in each worktree
- Some IDEs may need restart when switching worktrees
- Git hooks are shared across all worktrees

## Getting Help

Comprehensive built-in help is available for all commands:

```bash
# Overview and quick reference
wthelp

# Detailed help for specific commands
wthelp wt
wthelp wtclean
wthelp wtlist
wthelp wts

# Configuration reference
wthelp config

# Alternative syntax (also works)
wt --help
wtclean --help
wtlist --help
wts --help
```

The help system includes:
- Command usage and descriptions
- Real-world examples and scenarios
- Configuration options explained
- Common workflows and patterns
- Troubleshooting tips

## Contributing

PRs welcome! Please ensure:

1. Scripts pass shellcheck
2. Functions work in both bash and zsh
3. Destructive operations have confirmations
4. Documentation updated for new features
5. Help text added for new commands

## License

MIT - See [LICENSE](LICENSE) file

## Acknowledgments

Inspired by Git's worktree feature and the parallel development workflows it enables.

---

**Remember:** Branches are now directories. Stop switching, start `cd`-ing.
