# Changelog

All notable changes to Git Worktree Utils will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- Initial release
- `wt` command for creating and switching worktrees
- `wtclean` command for cleaning orphaned directories
- `wtlist` command for detailed worktree information
- `wts` command for interactive worktree switching
- `wthelp` command for inline help
- Automatic branch detection (new/local/remote)
- Directory conflict resolution
- Orphaned directory cleanup
- Configuration file support
- Comprehensive test suite
- Installation and uninstallation scripts

### Features
- Auto-prune broken worktree references
- Smart branch name sanitization
- Submodule initialization support
- Colored output with status indicators
- Interactive confirmation for destructive operations
- Configuration via ~/.config/git-worktree-utils/config

### Security
- Confirmation prompts before deleting directories
- Backup creation during installation/uninstallation
- Safe handling of special characters in branch names
