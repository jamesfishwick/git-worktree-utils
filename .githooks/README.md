# Git Hooks

Development git hooks for maintaining code quality.

## Setup

Run once after cloning:

```bash
./setup-hooks.sh
```

This configures git to use hooks from `.githooks/` directory.

## Hooks

### pre-commit
Runs before each commit:
- Shellcheck validation (if installed)
- Bash syntax checking
- File structure validation

### pre-push
Runs before pushing:
- Full test suite execution

## Bypassing Hooks

Use sparingly when you need to commit/push despite hook failures:

```bash
git commit --no-verify
git push --no-verify
```

## Installing Shellcheck

Recommended for pre-commit checks:

```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
apt-get install shellcheck

# Others
https://github.com/koalaman/shellcheck#installing
```
