.PHONY: install uninstall test lint clean help

# Default target
help:
	@echo "Git Worktree Utils - Makefile Commands"
	@echo ""
	@echo "  make install    Install git-worktree-utils"
	@echo "  make uninstall  Remove git-worktree-utils"
	@echo "  make test       Run test suite"
	@echo "  make lint       Check scripts with shellcheck"
	@echo "  make clean      Clean up test artifacts"
	@echo "  make help       Show this help message"
	@echo ""

install:
	@echo "Installing Git Worktree Utils..."
	@chmod +x install.sh
	@./install.sh

uninstall:
	@echo "Uninstalling Git Worktree Utils..."
	@chmod +x uninstall.sh
	@./uninstall.sh

test:
	@echo "Running test suite..."
	@chmod +x test.sh
	@./test.sh

lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck git-worktree-utils.sh install.sh uninstall.sh test.sh; \
		echo "✓ All scripts pass shellcheck"; \
	else \
		echo "⚠️  shellcheck not installed. Install with:"; \
		echo "  brew install shellcheck  # macOS"; \
		echo "  apt install shellcheck   # Ubuntu/Debian"; \
	fi

clean:
	@echo "Cleaning up..."
	@rm -rf /tmp/gwt-test-*
	@rm -f *.backup *.tmp *.swp
	@echo "✓ Cleaned"

# Development targets
dev-install:
	@echo "Installing in development mode (XDG-aware)..."
	@CONFIG_HOME="$${XDG_CONFIG_HOME:-$${HOME}/.config}"; \
	  mkdir -p "$$CONFIG_HOME/git-worktree-utils" && \
	  cp git-worktree-utils.sh "$$CONFIG_HOME/git-worktree-utils/" && \
	  echo "✓ Installed to $$CONFIG_HOME/git-worktree-utils/" && \
	  echo "Source it with: source \"$$CONFIG_HOME/git-worktree-utils/git-worktree-utils.sh\""
