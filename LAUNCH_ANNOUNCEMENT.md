# Launch Announcement - git-worktree-utils

## Short Version (Twitter/X, 280 chars)

🚀 Launching git-worktree-utils: A lightweight, zero-install worktree manager for bash enthusiasts.

Single script. Zero dependencies. Just source and go.

Perfect for dotfile minimalists who want simple git worktree management.

https://github.com/jamesfishwick/git-worktree-utils

---

## Medium Version (Reddit, HN, Dev.to intro)

**Launching git-worktree-utils: Lightweight Git Worktree Management for Bash Users**

I built a minimal git worktree manager that solves one problem well: making git worktrees easy from the command line.

**What it does:**
- `wt feature/auth` - Create/switch to worktree (no more typing branch names twice)
- `wtlist` - See all worktrees with status
- `wtclean` - Remove orphaned directories automatically
- `wts` - Interactive switcher between worktrees
- `wthelp` - Comprehensive built-in documentation

**Why it exists:**
Git worktrees are powerful but have rough CLI UX. Tools like Branchyard offer great IDE integration, but I wanted something simpler for shell-based workflows.

**Philosophy:**
- Single bash script (988 lines)
- Zero dependencies (bash + git)
- Source-based, not installed
- XDG-compliant
- Dotfile-friendly

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash
```

Perfect for developers who value simplicity over features and want their tools to live alongside their dotfiles.

**Links:**
- GitHub: https://github.com/jamesfishwick/git-worktree-utils
- [Blog post with full details](link-to-blog-post)

---

## Show HN Version

**Show HN: git-worktree-utils – Lightweight worktree manager for bash users**

I've been using git worktrees for years but found the native commands tedious. Type branch names twice, remember flags, manually clean up orphaned directories.

Instead of building a feature-rich tool like Branchyard (which is excellent if you want VS Code integration), I wanted something minimal for shell-based workflows.

git-worktree-utils is a single bash script that makes worktrees easy:

- `wt feature/auth` instead of `git worktree add ../path -b feature/auth`
- Automatic directory naming with configurable patterns
- Interactive switcher between worktrees
- Cleanup automation for orphaned directories
- Comprehensive help system built-in

Design principles:
- Zero dependencies (bash + git)
- Source-based, not installed (dotfile-friendly)
- XDG-compliant configuration
- Cross-platform (macOS, Linux, BSD)
- ~1000 lines, well-documented

I'm not trying to compete with feature-rich tools. This is for minimalists who want one problem solved well.

GitHub: https://github.com/jamesfishwick/git-worktree-utils

Happy to answer questions about design decisions, worktree workflows, or why I chose this approach!

---

## Reddit r/git Version

**[Tool] git-worktree-utils: Lightweight bash utilities for easier worktree management**

I've been frustrated with git worktree's CLI UX for a while. The commands are verbose, you type branch names twice, and cleanup is manual. I wanted something simpler than existing tools.

**Enter git-worktree-utils:**

A single bash script that streamlines common worktree operations:

```bash
# Instead of: git worktree add ../myapp-feature-auth -b feature/auth
wt feature/auth

# Instead of: git worktree list + cd ../path
wts  # Interactive switcher

# Instead of: manually finding and deleting old directories
wtclean
```

**Key features:**
- Automatic directory naming (configurable patterns)
- Smart branch detection (local/remote/new)
- Interactive worktree switcher
- Orphaned directory cleanup
- Comprehensive built-in help
- Submodule auto-initialization

**Why not just use Branchyard?**

Branchyard is excellent if you want VS Code integration and git hooks. I wanted something lighter for shell workflows - source-based, dotfile-friendly, zero dependencies.

**Philosophy:**
- Solve one problem well
- No build steps, no package managers
- Single script you can read and understand
- Perfect for dotfile enthusiasts

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash
```

**Project:** https://github.com/jamesfishwick/git-worktree-utils

Would love feedback from fellow worktree users! What pain points am I missing?

---

## Dev.to Version

```markdown
---
title: Introducing git-worktree-utils: Lightweight Worktree Management for Bash Users
published: false
description: A minimal, dotfile-friendly git worktree manager that solves one problem well
tags: git, bash, cli, opensource
---

# Introducing git-worktree-utils: Lightweight Worktree Management for Bash Users

Git worktrees are powerful, but the CLI experience leaves much to be desired. I built git-worktree-utils to fix that—a lightweight, bash-native tool that makes worktrees easy.

## The Problem

If you've used git worktrees, you know these pain points:

```bash
# Too verbose
git worktree add ../myapp-feature-auth -b feature/auth

# Branch name typed twice
git worktree add -b new-feature ../myapp-new-feature new-feature

# Manual cleanup
# You delete branches, directories stick around
# Git doesn't clean up orphaned directories automatically
```

## The Solution

git-worktree-utils simplifies everything:

```bash
# One command, auto-detects everything
wt feature/auth

# Interactive switcher
wts

# Smart cleanup
wtclean
```

## Why Another Tool?

[Branchyard](https://github.com/SivaramPg/branchyard) exists and it's excellent. If you want VS Code integration, git hooks, and a feature-rich CLI, use Branchyard.

I wanted something different:
- **Simpler** - Single bash script, no build step
- **Dotfile-friendly** - Source it, don't install it
- **Shell-native** - Built for bash/zsh power users
- **Minimal** - Zero dependencies beyond bash + git

## Features

### Smart Worktree Creation

```bash
wt feature/auth
# Automatically:
# - Creates ../myapp-feature-auth/
# - Detects if branch is local/remote/new
# - Initializes submodules if present
# - Switches to the directory
```

### Configurable Patterns

```bash
# ~/.config/git-worktree-utils/config
GWT_DIR_PATTERN="{base}-{branch}"           # myapp-feature-auth
# GWT_DIR_PATTERN="{branch}"                 # feature-auth
# GWT_DIR_PATTERN="worktrees/{base}/{branch}" # nested structure
```

### Interactive Switcher

```bash
wts

# Select worktree to switch to:
#   1) /Users/dev/myapp [CURRENT]
#   2) /Users/dev/myapp-feature-auth
#   3) /Users/dev/myapp-hotfix-urgent
# Enter number: 2
# ✓ Switched to /Users/dev/myapp-feature-auth
```

### Smart Cleanup

```bash
wtclean

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

### Detailed Status

```bash
wtlist

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

## Installation

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash

# Or manual
mkdir -p ~/.config/git-worktree-utils
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/git-worktree-utils.sh \
  -o ~/.config/git-worktree-utils/git-worktree-utils.sh
echo 'source ~/.config/git-worktree-utils/git-worktree-utils.sh' >> ~/.bashrc
```

## Design Philosophy

**Solve one problem well.** Make git worktrees easy from the command line. Nothing more.

- **Lightweight** - 988 lines of bash, that's it
- **Zero dependencies** - Bash + git, nothing else
- **Dotfile-friendly** - Source-based, lives with your dotfiles
- **Shell-native** - Built for terminal workflows
- **XDG-compliant** - Respects config directory standards

## Real-World Workflows

### Emergency Hotfix

```bash
# Currently on feature branch
wt hotfix/critical-security-fix
# Instant clean environment
# Fix, commit, push
# cd - back to feature work
```

### Code Review

```bash
wt pr/review-123
# Test locally
# When done: wtclean removes it
```

### Parallel Development

```bash
wt experiment/approach-a
wt experiment/approach-b
diff -r ../myapp-experiment-approach-a ../myapp-experiment-approach-b
# Keep the better one, wtclean the other
```

## Technical Details

**Cross-platform:**
- macOS (native stat)
- Linux (native stat)
- BSD (fallback mode)

**Smart about:**
- Spaces in paths (uses porcelain format)
- Broken worktree references (auto-prunes)
- Submodules (auto-initializes)
- XDG compliance (follows standards)

**Well-documented:**
- Comprehensive inline documentation
- Built-in help system (`wthelp`)
- Example configuration
- Troubleshooting guide

## Contributing

The project prioritizes:
- Simplicity over features
- Compatibility over cutting-edge
- Shell-native over cross-language
- Zero dependencies

Open to contributions that align with these principles!

## Links

- **GitHub:** https://github.com/jamesfishwick/git-worktree-utils
- **License:** MIT

## Conclusion

If you value simplicity, want dotfile-friendly tools, and work primarily in the terminal, git-worktree-utils might be for you.

It's not trying to be Branchyard. It's trying to be the minimal, bash-native worktree manager that solves one problem really well.

Try it out and let me know what you think!
```

---

## LinkedIn Version

**Launching git-worktree-utils: A New Open Source Tool**

I'm excited to share git-worktree-utils, a lightweight git worktree manager I built to solve a daily workflow friction point.

**The Problem:**
Git worktrees are powerful for parallel development, but the CLI experience is verbose and cleanup is manual. Existing tools are feature-rich but heavier than I needed.

**The Solution:**
A single bash script (988 lines) that simplifies worktree management:
- One-command worktree creation
- Automatic directory naming
- Interactive switching
- Smart cleanup

**Design Philosophy:**
- Zero dependencies (bash + git only)
- Dotfile-friendly (source-based)
- Solve one problem well
- Minimal over feature-rich

**Perfect for:**
Developers who value simplicity, work primarily in terminal environments, and prefer lightweight tools that integrate seamlessly with dotfiles.

**Key Learning:**
Sometimes the best solution isn't the most feature-rich—it's the one that fits naturally into existing workflows without adding complexity.

Open sourced under MIT license. Link in comments.

#OpenSource #Git #DeveloperTools #Bash #SoftwareDevelopment

---

**Comments to include:**
GitHub: https://github.com/jamesfishwick/git-worktree-utils
Blog post: [link-to-blog-post]
