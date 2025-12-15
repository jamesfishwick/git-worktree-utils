#!/usr/bin/env bash
# Git Worktree Utils - Test Suite

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/gwt-test-$$"
TEST_REPO="${TEST_DIR}/test-repo"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Source the script and help
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/git-worktree-utils.sh"

# Disable confirmations for all tests
export GWT_CONFIRM_DELETE=false

# Helper functions
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

test_start() {
    print_color "$BLUE" "→ Testing: $1"
}

test_pass() {
    print_color "$GREEN" "  ✓ PASS: $1"
    ((++TESTS_PASSED)) || true
}

test_fail() {
    print_color "$RED" "  ✗ FAIL: $1"
    ((++TESTS_FAILED)) || true
}

cleanup() {
    cd /tmp
    rm -rf "$TEST_DIR"
}

# Set up test environment
setup() {
    print_color "$YELLOW" "Setting up test environment..."
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Create test repository
    mkdir "$TEST_REPO"
    cd "$TEST_REPO"
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    echo "# Test Repo" > README.md
    git add README.md
    git commit -m "Initial commit"
    
    print_color "$GREEN" "✓ Test environment ready"
    echo
}

# Clean up on exit
trap cleanup EXIT

# Header
echo
print_color "$BLUE" "==================================="
print_color "$BLUE" "  Git Worktree Utils Test Suite"
print_color "$BLUE" "==================================="
echo

# Set up
setup

# Test 1: List worktrees in empty repo
test_start "List worktrees (empty)"
if output=$(wt 2>&1); then
    if echo "$output" | grep -q "test-repo"; then
        test_pass "Listed main worktree"
    else
        test_fail "Failed to list main worktree"
    fi
else
    test_fail "Command failed"
fi

# Test 2: Create worktree for new branch
test_start "Create worktree for new branch"
if wt feature/test-branch > /dev/null 2>&1; then
    if [[ -d "../test-repo-feature-test-branch" ]]; then
        test_pass "Created worktree directory"
    else
        test_fail "Directory not created"
    fi
    
    # Return to main repo
    cd "$TEST_REPO"
else
    test_fail "Failed to create worktree"
fi

# Test 3: Create worktree for existing branch
test_start "Create worktree for existing branch"
git checkout -b existing-branch 2>/dev/null
echo "test" > test.txt
git add test.txt
git commit -m "Test commit" 2>/dev/null
git checkout main 2>/dev/null

if wt existing-branch > /dev/null 2>&1; then
    if [[ -f "../test-repo-existing-branch/test.txt" ]]; then
        test_pass "Checked out existing branch correctly"
    else
        test_fail "Files not present in worktree"
    fi
    cd "$TEST_REPO"
else
    test_fail "Failed to create worktree for existing branch"
fi

# Test 4: Handle directory conflicts
test_start "Handle existing directory"
mkdir -p "../test-repo-conflict-branch"
echo "existing file" > "../test-repo-conflict-branch/existing.txt"

if wt conflict-branch > /dev/null 2>&1; then
    if [[ ! -f "../test-repo-conflict-branch/existing.txt" ]]; then
        test_pass "Handled directory conflict"
    else
        test_fail "Did not clean up existing directory"
    fi
    cd "$TEST_REPO"
else
    test_fail "Failed to handle directory conflict"
fi

# Test 5: List all worktrees
test_start "List multiple worktrees"
if output=$(wt 2>&1); then
    worktree_count=$(echo "$output" | grep -c "test-repo")
    if [[ $worktree_count -ge 3 ]]; then
        test_pass "Listed all worktrees ($worktree_count found)"
    else
        test_fail "Missing worktrees (only $worktree_count found)"
    fi
else
    test_fail "Failed to list worktrees"
fi

# Test 6: Cleanup orphaned directories
test_start "Clean orphaned directories"

# Create orphaned directory (must match cleanup patterns like *-feature*)
mkdir -p "../test-repo-feature-orphan"
echo "orphan" > "../test-repo-feature-orphan/file.txt"

# Run cleanup
if wtclean > /dev/null 2>&1; then
    if [[ ! -d "../test-repo-feature-orphan" ]]; then
        test_pass "Cleaned orphaned directory"
    else
        test_fail "Orphaned directory still exists"
    fi
else
    test_fail "Cleanup command failed"
fi

# Test 7: Worktree with complex branch names
test_start "Complex branch names"
if wt feature/user-auth/oauth-2.0 > /dev/null 2>&1; then
    if [[ -d "../test-repo-feature-user-auth-oauth-2.0" ]]; then
        test_pass "Handled complex branch name"
    else
        test_fail "Failed with complex branch name"
    fi
    cd "$TEST_REPO"
else
    test_fail "Failed to create worktree with complex name"
fi

# Test 8: Switch to existing worktree
test_start "Switch to existing worktree"
if wt feature/test-branch > /dev/null 2>&1; then
    if [[ "$(basename $(pwd))" == "test-repo-feature-test-branch" ]]; then
        test_pass "Switched to existing worktree"
    else
        test_fail "Did not switch to correct directory"
    fi
    cd "$TEST_REPO"
else
    test_fail "Failed to switch to existing worktree"
fi

# Test 9: Error handling outside git repo
test_start "Error handling outside git repo"
cd /tmp
if ! wt test-branch 2>&1 | grep -q "Not in a git repository"; then
    test_fail "Did not detect non-git directory"
else
    test_pass "Correctly detected non-git directory"
fi
cd "$TEST_REPO"

# Test 10: Detailed list function
test_start "Detailed worktree list"
if output=$(wtlist 2>&1); then
    if echo "$output" | grep -q "Branch:"; then
        test_pass "Detailed list shows branch info"
    else
        test_fail "Missing branch information"
    fi
else
    test_fail "List command failed"
fi

# Summary
echo
print_color "$BLUE" "==================================="
print_color "$BLUE" "          Test Summary"
print_color "$BLUE" "==================================="
echo
print_color "$GREEN" "Passed: $TESTS_PASSED"
if [[ $TESTS_FAILED -gt 0 ]]; then
    print_color "$RED" "Failed: $TESTS_FAILED"
    exit 1
else
    print_color "$GREEN" "Failed: 0"
    echo
    print_color "$GREEN" "✓ All tests passed!"
fi
echo
