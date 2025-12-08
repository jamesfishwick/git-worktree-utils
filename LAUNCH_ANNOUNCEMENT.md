# Launch Announcement - git-worktree-utils

## Short Version (Twitter/X, 280 chars)

Launching git-worktree-utils: Lightweight worktree manager for bash users.

Single script. Zero dependencies. Source and go.

For dotfile minimalists who want simple git worktree management.

https://github.com/jamesfishwick/git-worktree-utils

---

## Medium Version (Reddit, HN, Dev.to intro)

**Launching git-worktree-utils: Lightweight Git Worktree Management for Bash Users**

I built a minimal git worktree manager that solves one problem: making git worktrees easy from the command line.

**What it does:**
- `wt feature/auth` - Create/switch to worktree (no double-typing)
- `wtlist` - See all worktrees with status
- `wtclean` - Remove orphaned directories automatically
- `wts` - Interactive switcher
- `wthelp` - Built-in docs

**Why it exists:**
Git worktrees have rough CLI UX. Branchyard offers IDE integration, but I wanted something simpler for shell workflows.

**Design:**
- Single bash script (988 lines)
- Zero dependencies (bash + git)
- Source-based, not installed
- XDG-compliant
- Dotfile-friendly

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash
```

For developers who value simplicity and want tools that live alongside dotfiles.

**Links:**
- GitHub: https://github.com/jamesfishwick/git-worktree-utils
- [Blog post](link-to-blog-post)

---

## Show HN Version

**Show HN: git-worktree-utils – Lightweight worktree manager for bash users**

I've used git worktrees for years but found native commands tedious. Type branch names twice, remember flags, manually clean orphaned directories.

Branchyard is excellent if you want VS Code integration, but I wanted something minimal for shell workflows.

git-worktree-utils is a single bash script:

- `wt feature/auth` instead of `git worktree add ../path -b feature/auth`
- Automatic directory naming with configurable patterns
- Interactive switcher
- Cleanup automation
- Built-in help system

Design principles:
- Zero dependencies (bash + git)
- Source-based, not installed (dotfile-friendly)
- XDG-compliant config
- Cross-platform (macOS, Linux, BSD)
- ~1000 lines, well-documented

Not competing with feature-rich tools. For minimalists who want one problem solved well.

GitHub: https://github.com/jamesfishwick/git-worktree-utils

Questions about design decisions, worktree workflows, or implementation welcome.

---

## Reddit r/git Version

**[Tool] git-worktree-utils: Lightweight bash utilities for easier worktree management**

Git worktree CLI is verbose. Branch names typed twice, cleanup is manual. I wanted something simpler than existing tools.

**git-worktree-utils:**

```bash
# Instead of: git worktree add ../myapp-feature-auth -b feature/auth
wt feature/auth

# Instead of: git worktree list + cd ../path
wts  # Interactive switcher

# Instead of: manually deleting old directories
wtclean
```

**Features:**
- Automatic directory naming (configurable patterns)
- Smart branch detection (local/remote/new)
- Interactive switcher
- Orphaned directory cleanup
- Built-in help
- Submodule auto-init

**Why not Branchyard?**
Branchyard has VS Code integration and git hooks. I wanted something lighter for shell workflows—source-based, dotfile-friendly, zero dependencies.

**Design:**
- Solve one problem well
- No build steps, no package managers
- Single script you can read
- Dotfile integration

**Install:**
```bash
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash
```

**Project:** https://github.com/jamesfishwick/git-worktree-utils

Feedback from worktree users welcome. What pain points am I missing?

---

## Dev.to Version

```markdown
---
title: Introducing git-worktree-utils: Lightweight Worktree Management for Bash Users
published: false
description: A minimal, dotfile-friendly git worktree manager
tags: git, bash, cli, opensource
---

# Introducing git-worktree-utils: Lightweight Worktree Management for Bash Users

Git worktrees are powerful, but the CLI is tedious. I built git-worktree-utils to fix that—a lightweight, bash-native tool.

## The Problem

```bash
# Too verbose
git worktree add ../myapp-feature-auth -b feature/auth

# Branch name typed twice
git worktree add -b new-feature ../myapp-new-feature new-feature

# Manual cleanup
# Delete branches, directories stick around
```

## The Solution

```bash
# One command
wt feature/auth

# Interactive switcher
wts

# Smart cleanup
wtclean
```

## Why Another Tool?

[Branchyard](https://github.com/SivaramPg/branchyard) has VS Code integration, git hooks, feature-rich CLI. Use it if you want those.

I wanted:
- Simpler - Single bash script
- Dotfile-friendly - Source it, don't install
- Shell-native - Built for terminal
- Minimal - Zero dependencies

## Features

### Smart Creation

```bash
wt feature/auth
# Auto-detects local/remote/new
# Creates ../myapp-feature-auth/
# Initializes submodules
# Switches directory
```

### Configurable Patterns

```bash
# ~/.config/git-worktree-utils/config
GWT_DIR_PATTERN="{base}-{branch}"           # myapp-feature-auth
# GWT_DIR_PATTERN="{branch}"                 # feature-auth
# GWT_DIR_PATTERN="worktrees/{base}/{branch}" # nested
```

### Interactive Switcher

```bash
wts

# Select worktree:
#   1) /Users/dev/myapp [CURRENT]
#   2) /Users/dev/myapp-feature-auth
# Enter number: 2
```

### Smart Cleanup

```bash
wtclean

# Found 3 orphaned directories:
#   ../myapp-feature-old (458M)
#   ../myapp-hotfix-merged (12M)
# Delete all? (y/N)
```

### Built-in Help

```bash
wthelp              # Overview
wthelp wt           # Command details
wthelp config       # Config reference
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash
```

## Design Philosophy

Solve one problem well. Make git worktrees easy from the command line.

- Lightweight - 988 lines of bash
- Zero dependencies - Bash + git only
- Dotfile-friendly - Lives with your dotfiles
- Shell-native - Terminal workflows
- XDG-compliant - Config standards

## Workflows

### Emergency Hotfix

```bash
wt hotfix/critical-security-fix
# Fix, commit, push
cd -  # Back to feature
```

### Code Review

```bash
wt pr/123
# Test locally
wtclean  # Remove when done
```

### Parallel Development

```bash
wt approach-a
wt approach-b
diff -r ../myapp-approach-*
```

## Links

- GitHub: https://github.com/jamesfishwick/git-worktree-utils
- License: MIT

Try it out.
```

---

## LinkedIn Version

**Launching git-worktree-utils: Open Source Git Worktree Manager**

I'm sharing git-worktree-utils, a lightweight git worktree manager I built to solve daily workflow friction.

**Problem:**
Git worktrees are powerful for parallel development, but the CLI is verbose and cleanup is manual. Existing tools are feature-rich but heavier than needed.

**Solution:**
Single bash script (988 lines) that simplifies worktree management:
- One-command worktree creation
- Automatic directory naming
- Interactive switching
- Smart cleanup

**Design:**
- Zero dependencies (bash + git only)
- Dotfile-friendly (source-based)
- Solve one problem well
- Minimal over feature-rich

**For:**
Developers who value simplicity, work in terminals, and prefer lightweight tools that integrate with dotfiles.

**Learning:**
The best solution isn't the most feature-rich—it's the one that fits naturally into existing workflows without adding complexity.

Open sourced under MIT.

#OpenSource #Git #DeveloperTools #Bash

**Project:** https://github.com/jamesfishwick/git-worktree-utils
