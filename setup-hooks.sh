#!/usr/bin/env bash
# Git Worktree Utils - Setup Development Hooks

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo
echo -e "${YELLOW}Setting up git hooks for development...${NC}"
echo

# Configure git to use .githooks directory
git config core.hooksPath .githooks

echo -e "${GREEN}✓ Git hooks configured${NC}"
echo
echo "Hooks installed:"
echo "  - pre-commit: Shellcheck + syntax validation"
echo "  - pre-push: Full test suite"
echo
echo "To bypass hooks (use sparingly):"
echo "  git commit --no-verify"
echo "  git push --no-verify"
echo
