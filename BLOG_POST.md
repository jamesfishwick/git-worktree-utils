# I Built a Lightweight Git Worktree Manager (Because I Couldn't Find One)

*Why I created git-worktree-utils when Branchyard exists, and why "minimal" isn't a compromise—it's a feature.*

---

## The Itch That Needed Scratching

I love git worktrees. The concept is brilliant: instead of constantly switching branches in one directory, you have multiple directories with different branches checked out simultaneously. No more stashing. No more losing IDE state. Clean separation of contexts.

But the CLI experience? Rough.

```bash
# Create a worktree the native way
git worktree add ../myapp-feature-auth -b feature/auth

# Wait, did I just type the branch name twice?
# And I have to remember to add -b for new branches?
# And figure out the directory path myself?
```

After months of this friction, I looked for tools to simplify it. I found [Branchyard](https://github.com/SivaramPg/branchyard)—and it's genuinely excellent. VS Code integration, git hooks, auto-cleanup on branch delete. Feature-rich and well-designed.

But it felt... heavy for my needs. I wanted something simpler. Something that lived in my dotfiles. Something I could read in 20 minutes.

So I built **git-worktree-utils**.

## What It Does (In 30 Seconds)

```bash
# Create/switch to worktree (auto-detects local/remote/new branches)
wt feature/auth

# List all worktrees with status
wtlist

# Interactive switcher
wts

# Clean up orphaned directories
wtclean

# Comprehensive help
wthelp
```

That's it. Five commands. One file. Zero dependencies beyond bash and git.

## The Design Philosophy: Minimal Is a Feature

When I say "minimal," I don't mean "missing features." I mean **intentionally focused**.

### What git-worktree-utils IS:
- ✅ A bash script (988 lines, well-documented)
- ✅ Source-based (lives in `~/.config`, sourced in your shell)
- ✅ XDG-compliant (respects your config directory standards)
- ✅ Dotfile-friendly (check it into your dotfiles repo)
- ✅ Cross-platform (macOS, Linux, BSD)
- ✅ Zero dependencies (bash + git, that's it)

### What it's NOT:
- ❌ A feature-rich alternative to Branchyard
- ❌ Something that integrates with your IDE
- ❌ A tool with git hook automation
- ❌ Packaged software you install via package manager

This isn't a limitation—**it's the point.**

## Why Choose Simplicity?

### 1. **You Can Actually Read It**

The entire codebase is 988 lines of bash. Comments included. You can read it in 20 minutes and understand exactly what it does.

When something breaks (and something always breaks), you can fix it. No black box. No "well, it worked yesterday."

### 2. **It Lives With Your Dotfiles**

I manage my dotfiles in git. My shell config, my vim setup, my git aliases. Why should my worktree manager be different?

```bash
# In my dotfiles repo
.config/git-worktree-utils/git-worktree-utils.sh

# In my ~/.zshrc
source ~/.config/git-worktree-utils/git-worktree-utils.sh
```

One repo. All my config. Synchronized across machines. No special installation.

### 3. **Zero Dependency Hell**

It's bash. You have bash. It uses git commands. You have git.

That's it. No Python runtime. No Node modules. No Ruby gems. No version conflicts. No `npm install` that pulls in 47 packages.

### 4. **It Just Works (Forever)**

Bash is stable. Git is stable. The script uses standard POSIX commands with platform-specific fallbacks.

Write it once in 2025, it'll still work in 2035. No framework migrations. No deprecated APIs. No "please upgrade to v2."

## The Features That Matter

### Smart Worktree Creation

```bash
wt feature/auth
```

This one command:
- Auto-detects if the branch is local, remote, or new
- Creates directory with configurable pattern (`{base}-{branch}`)
- Handles spaces in paths correctly (uses porcelain format)
- Initializes submodules if present
- Switches to the directory automatically

No flags to remember. No branch names typed twice. Just works.

### Configurable Directory Patterns

```bash
# ~/.config/git-worktree-utils/config
GWT_DIR_PATTERN="{base}-{branch}"

# Examples:
# {base}-{branch}           → myapp-feature-auth
# {branch}                  → feature-auth
# worktrees/{base}/{branch} → worktrees/myapp/feature-auth
```

Your workflow, your structure. Not mine.

### Interactive Switcher

```bash
$ wts

Select worktree to switch to:
  1) /Users/dev/myapp [CURRENT]
  2) /Users/dev/myapp-feature-auth
  3) /Users/dev/myapp-hotfix-urgent

Enter number (1-3): 2
✓ Switched to /Users/dev/myapp-feature-auth
```

Beats typing `cd ../myapp-whatever` every time.

### Smart Cleanup

```bash
$ wtclean

=== Git Worktree Cleanup ===
→ Pruning broken worktree references...
→ Searching for orphaned directories...

Found 3 orphaned directories:
  ../myapp-feature-old (458M)
  ../myapp-hotfix-merged (12M)
  ../myapp-review-pr-123 (234M)

Delete all orphaned directories? (y/N)
```

Shows disk usage. Requires confirmation. Never touches active worktrees. Safe.

### Comprehensive Help System

```bash
wthelp              # General overview
wthelp wt           # Detailed command help
wthelp config       # Configuration reference
wthelp workflows    # Real-world examples
```

Documentation built into the tool. No "go read the GitHub README." Help is always one command away.

## Real-World Workflows

### Emergency Hotfix

You're deep in feature development. Production is on fire.

```bash
wt hotfix/critical-security-fix
# Instant clean environment on main branch
# Fix the bug
git push origin hotfix/critical-security-fix
# Back to feature work
cd -
```

Your feature work? Untouched. Exactly where you left it.

### Code Review

```bash
wt pr/review-123
# Test the PR locally
# Leave comments
# When done:
cd ../myapp
wtclean  # Removes the review worktree
```

No git juggling. No stashing. Just a clean review environment.

### Parallel Approaches

```bash
wt experiment/approach-a
# Implement solution A

wt experiment/approach-b
# Implement solution B

diff -r ../myapp-experiment-approach-a ../myapp-experiment-approach-b
# Compare, pick the winner, wtclean the loser
```

Try multiple approaches without branches conflicting. Keep the best. Delete the rest.

## Technical Decisions (The Interesting Parts)

### Porcelain Format for Robustness

Git worktree's default output isn't designed for parsing. Paths can have spaces. Branch names can have newlines (don't ask).

Solution: Use `git worktree list --porcelain` and parse it properly:

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

Rock solid. Handles edge cases. Doesn't break on weird paths.

### XDG Compliance (With Fallback)

```bash
GWT_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
GWT_CONFIG_DIR="${GWT_CONFIG_HOME}/git-worktree-utils"
```

Respects `XDG_CONFIG_HOME` if set. Falls back to `~/.config` if not. Works everywhere.

### Platform-Specific Stat Commands

macOS uses BSD `stat`. Linux uses GNU `stat`. They have different flags.

```bash
case "$(uname -s)" in
    Darwin)
        stat -f "%m %N" "$path"
        ;;
    Linux)
        stat -c "%Y %n" "$path"
        ;;
    *)
        # Fallback for other systems
        find "$dir" -mindepth 1 -maxdepth 1 -print
        ;;
esac
```

Write once, run anywhere (with bash and git).

### Helper Function Pattern

Every helper function is prefixed `_gwt_`. Private by convention. Clear namespace.

```bash
_gwt_print()                   # Colored output
_gwt_get_worktree_paths()      # Parse worktree paths
_gwt_list_recent()             # Platform-aware file listing
_gwt_display_worktree_info()   # Comprehensive worktree display
```

No conflicts with user's environment. Easy to grep.

## What I Learned Building This

### 1. **Minimal ≠ Incomplete**

You don't need 50 features to solve a problem well. You need the RIGHT features, thoughtfully designed.

Five commands. Each does one thing well. Together they solve 95% of worktree pain points.

### 2. **Documentation Is a Feature**

The built-in help system (`wthelp`) isn't an afterthought—it's a core feature. Help should be comprehensive, accessible, and always available.

No "just read the docs." The docs ARE the tool.

### 3. **Bash Is Underrated**

Yes, it has quirks. Yes, quoting is annoying. But for system utilities? It's perfect.

No runtime. No dependencies. Runs everywhere. Fast. Debuggable. Done.

### 4. **Open Source Needs Positioning**

"I built a tool" isn't enough. You need to answer:
- Why does this exist when X exists?
- Who is this for?
- What's the philosophy?

Being honest about scope isn't weakness—it's clarity.

## Why Not Just Use Branchyard?

**You should!** If you want:
- VS Code workspace integration
- Git hook automation
- Auto-cleanup on branch delete
- Feature-rich CLI with personality

Branchyard is excellent. Use it.

But if you want:
- Dotfile-friendly tool
- Zero dependencies
- Source-based configuration
- Minimal, shell-native design
- Something you can read in 20 minutes

Then git-worktree-utils might be your thing.

**Different tools for different workflows. Both are valid.**

## Try It

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh | bash

# Or inspect first
curl -fsSL https://raw.githubusercontent.com/jamesfishwick/git-worktree-utils/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

**Project:** https://github.com/jamesfishwick/git-worktree-utils
**License:** MIT
**Lines of Code:** 988 (including comments and docs)
**Dependencies:** bash + git

## Final Thoughts

Building git-worktree-utils taught me that "minimal" is a design choice, not a limitation.

Sometimes the best tool isn't the most feature-rich. It's the one that:
- Solves your specific problem
- Integrates seamlessly into your workflow
- You can understand, modify, and maintain
- Does one thing really, really well

For me, that's a 988-line bash script I can keep in my dotfiles forever.

What's your version of "minimal"? I'd love to hear about tools you've built that prioritize simplicity.

---

*Questions? Feedback? Found a bug? [Open an issue](https://github.com/jamesfishwick/git-worktree-utils/issues) or let me know in the comments.*

---

## Appendix: Quick Reference

### Commands

```bash
wt [branch]        # Create/switch to worktree
wtlist             # Detailed worktree info
wtclean            # Clean up orphaned directories
wts                # Interactive switcher
wthelp [topic]     # Comprehensive help
```

### Configuration

```bash
# ~/.config/git-worktree-utils/config
GWT_DIR_PATTERN="{base}-{branch}"              # Directory naming
GWT_AUTO_PRUNE=true                            # Auto-prune broken refs
GWT_CONFIRM_DELETE=true                        # Confirm before delete
GWT_CLEANUP_PATTERNS="*-feature* *-hotfix*"    # Cleanup patterns
GWT_USE_COLOR=true                             # Colored output
```

### Common Workflows

**Emergency hotfix:**
```bash
wt hotfix/urgent && fix-the-bug && git push && cd -
```

**Code review:**
```bash
wt pr/123 && test-locally && cd ../myapp && wtclean
```

**Parallel approaches:**
```bash
wt approach-a && wt approach-b && diff -r ../myapp-approach-*
```

---

*Published: December 2025*
*Author: [James Fishwick](https://github.com/jamesfishwick)*
*Tags: #git #bash #cli #opensource #devtools*
