
# >>> Git Worktree Utils
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
if [[ -f "${CONFIG_HOME}/git-worktree-utils/git-worktree-utils.sh" ]]; then
  source "${CONFIG_HOME}/git-worktree-utils/git-worktree-utils.sh"
elif [[ -f "${HOME}/.config/git-worktree-utils/git-worktree-utils.sh" ]]; then
  # Legacy fallback
  source "${HOME}/.config/git-worktree-utils/git-worktree-utils.sh"
fi
# <<< Git Worktree Utils
