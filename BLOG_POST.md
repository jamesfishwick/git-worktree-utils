# I Built a Lightweight Git Worktree Manager (Because I Couldn't Find One)

Why I created git-worktree-utils when Branchyard exists, and why "minimal" isn't a compromise.

---

## The Problem

I use git worktrees regularly. Multiple branches checked out simultaneously in separate directories beats constant branch switching. No stashing, IDE state persists, contexts stay separated.

But the CLI is tedious:

```bash
git worktree add ../myapp-feature-auth -b feature/auth
# Branch name typed twice, manual -b flag, path calculated by hand
```

After months of this, I looked for tools. [Branchyard](https://github.com/SivaramPg/branchyard) has VS Code integration, git hooks, auto-cleanup. Well-designed, feature-rich.

Too heavy for me. I wanted something in my dotfiles. Something I could read in 20 minutes.

So I built git-worktree-utils.

## What It Does

```bash
wt feature/auth    # Create/switch to worktree
wtlist             # List with status
wts                # Interactive switcher
wtclean            # Clean orphaned directories
wthelp             # Built-in help
```

Five commands. One file. Bash + git only.

## Design Decisions

"Minimal" means intentionally focused, not feature-poor.

**What it is:**
- 988-line bash script
- Source-based (lives in ~/.config)
- XDG-compliant
- Checked into dotfiles
- Cross-platform (macOS, Linux, BSD)
- Zero dependencies

**What it's not:**
- Feature-complete alternative to Branchyard
- IDE-integrated
- Git hook automated
- Package manager distributed

This is the design, not a limitation.

## Why Simplicity Matters

### Readable
988 lines of bash, comments included. Read it in 20 minutes. When it breaks, you can fix it. No black box.

### Dotfile Integration
I manage dotfiles in git. Shell config, vim, git aliases. The worktree manager belongs there too.

```bash
# In dotfiles repo
.config/git-worktree-utils/git-worktree-utils.sh

# In ~/.zshrc
source ~/.config/git-worktree-utils/git-worktree-utils.sh
```

One repo, all config, synchronized across machines.

### Zero Dependencies
Bash and git. That's it. No Python, Node, Ruby, version conflicts, or 47-package `npm install`.

### Longevity
Bash is stable. Git is stable. POSIX commands with platform fallbacks. Write once in 2025, runs in 2035.

## Core Features

### Smart Worktree Creation

```bash
wt feature/auth
```

Auto-detects local/remote/new branches. Creates `{base}-{branch}` directory. Handles paths with spaces (porcelain format). Initializes submodules. Switches directory.

No flags. No double-typing branch names.

### Configurable Patterns

```bash
# ~/.config/git-worktree-utils/config
GWT_DIR_PATTERN="{base}-{branch}"

# Options:
# {base}-{branch}           -> myapp-feature-auth
# {branch}                  -> feature-auth
# worktrees/{base}/{branch} -> worktrees/myapp/feature-auth
```

Your workflow, your structure.

### Interactive Switcher

```bash
$ wts

Select worktree:
  1) /Users/dev/myapp [CURRENT]
  2) /Users/dev/myapp-feature-auth
  3) /Users/dev/myapp-hotfix-urgent

Enter number (1-3): 2
Switched to /Users/dev/myapp-feature-auth
```

### Cleanup Automation

```bash
$ wtclean

Git Worktree Cleanup
Pruning broken references...
Searching for orphaned directories...

Found 3 orphaned directories:
  ../myapp-feature-old (458M)
  ../myapp-hotfix-merged (12M)
  ../myapp-review-pr-123 (234M)

Delete all? (y/N)
```

Shows disk usage, requires confirmation, never touches active worktrees.

### Built-in Help

```bash
wthelp              # Overview
wthelp wt           # Command details
wthelp config       # Config reference
wthelp workflows    # Examples
```

Help built into the tool. No "read the GitHub README."

## Workflows

### Emergency Hotfix

```bash
wt hotfix/critical-security-fix
# Clean environment on main
# Fix, commit, push
cd -  # Back to feature work
```

Feature work untouched. Exactly where you left it.

### Code Review

```bash
wt pr/123
# Test locally
cd ../myapp
wtclean  # Remove review worktree
```

### Parallel Approaches

```bash
wt approach-a
wt approach-b
diff -r ../myapp-approach-a ../myapp-approach-b
# Keep winner, clean loser
```

## Technical Details

### Porcelain Format

Git's default output isn't parseable. Paths can have spaces. Branch names can have newlines.

```bash
while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
        worktree\ *)
            path=${line#worktree }
            ;;
        branch\ *)
            branch=${line#branch }
            ;;
    esac
done < <(git worktree list --porcelain)
```

Handles edge cases correctly.

### XDG Compliance

```bash
GWT_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
GWT_CONFIG_DIR="${GWT_CONFIG_HOME}/git-worktree-utils"
```

Respects XDG_CONFIG_HOME, falls back to ~/.config.

### Platform Detection

macOS uses BSD stat. Linux uses GNU stat. Different flags.

```bash
case "$(uname -s)" in
    Darwin)
        stat -f "%m %N" "$path"
        ;;
    Linux)
        stat -c "%Y %n" "$path"
        ;;
    *)
        # Fallback
        find "$dir" -mindepth 1 -maxdepth 1 -print
        ;;
esac
```

### Namespace Convention

All helpers prefixed `_gwt_`. Clear, no conflicts.

```bash
_gwt_print()                   # Colored output
_gwt_get_worktree_paths()      # Parse paths
_gwt_list_recent()             # File listing
_gwt_display_worktree_info()   # Info display
```

## What I Learned

### Minimal Doesn't Mean Incomplete
Five commands solve 95% of worktree pain. The right features, thoughtfully designed.

### Documentation Is Core
Built-in help isn't optional. Help should be always available, not "just read the docs."

### Bash Works
Despite quirks, bash is perfect for system utilities. No runtime, no dependencies, runs everywhere. Fast, debuggable.

### Positioning Matters
"I built a tool" isn't enough. Answer: Why does this exist when X exists? Who is this for? What's the philosophy?

## vs. Branchyard

Use [Branchyard](https://github.com/SivaramPg/branchyard) if you want VS Code integration, git hooks, auto-cleanup on branch delete, feature-rich CLI.

Use git-worktree-utils if you want dotfile-friendly, zero dependencies, source-based config, minimal shell-native design, readable in 20 minutes.

Different tools for different workflows.

## Install

```bash
# One-line
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash

# Or inspect first
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

**Project:** https://github.com/jamesfishwick/git-worktree-utils
**License:** MIT
**Lines:** 988

## Final Thoughts

"Minimal" is a design choice, not a limitation.

The best tool isn't the most feature-rich. It's the one that solves your problem, integrates into your workflow, and you can understand and maintain.

For me, that's a 988-line bash script in my dotfiles.

---

**Author:** [James Fishwick](https://github.com/jamesfishwick)
**Published:** December 2025

## Quick Reference

### Commands

```bash
wt [branch]        # Create/switch
wtlist             # Detailed info
wtclean            # Clean orphans
wts                # Interactive switch
wthelp [topic]     # Help
```

### Config

```bash
# ~/.config/git-worktree-utils/config
GWT_DIR_PATTERN="{base}-{branch}"
GWT_AUTO_PRUNE=true
GWT_CONFIRM_DELETE=true
GWT_CLEANUP_PATTERNS="*-feature* *-hotfix*"
GWT_USE_COLOR=true
```

### Workflows

```bash
# Emergency hotfix
wt hotfix/urgent && fix && git push && cd -

# Code review
wt pr/123 && test && cd ../myapp && wtclean

# Parallel approaches
wt approach-a && wt approach-b && diff -r ../myapp-approach-*
```
