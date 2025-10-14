# Makefile for zk - Zettelkasten knowledge management system

PREFIX ?= $(HOME)/.local
INSTALL_DIR = $(PREFIX)/zk
BIN_DIR = $(PREFIX)/bin
COMPLETION_DIR = $(HOME)/.bash_completion.d

.PHONY: help install uninstall clean test

help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

install: ## Install zk to the local system
	@echo "Installing zk to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(COMPLETION_DIR)
	@cp -f zk $(INSTALL_DIR)/zk
	@chmod +x $(INSTALL_DIR)/zk
	@cp -r cmd $(INSTALL_DIR)/
	@cp -r lib $(INSTALL_DIR)/
	@ln -sf $(INSTALL_DIR)/zk $(BIN_DIR)/zk
	@$(INSTALL_DIR)/zk completion > $(COMPLETION_DIR)/zk
	@echo "\nInstallation complete!"
	@echo "  - Executable: $(INSTALL_DIR)/zk"
	@echo "  - Symlink: $(BIN_DIR)/zk"
	@echo "  - Completion: $(COMPLETION_DIR)/zk"
	@echo "\nNext steps:"
	@echo "  1. Ensure $(BIN_DIR) is in your PATH"
	@echo "  2. Add to ~/.bashrc: source ~/.bash_completion.d/zk"
	@echo "  3. Run: zk init"

uninstall: ## Uninstall zk from the local system
	@echo "Uninstalling zk..."
	@rm -f $(BIN_DIR)/zk
	@rm -rf $(INSTALL_DIR)
	@rm -f $(COMPLETION_DIR)/zk
	@echo "Uninstall complete!"

clean: ## Clean up project (no-op)
	@echo "Nothing to clean (no build artifacts)"

test: ## Run all unit tests
	@echo "Running unit tests..."
	@bats test/unit/

# --- Release Management ---

.PHONY: release-patch release-minor release-major release install-hooks

release-patch: ## Bump patch version, commit, and tag
	@./scripts/version.sh patch
	$(eval NEW_VERSION = v$(shell cat VERSION))
	@./scripts/update_changelog.sh $(NEW_VERSION)
	@git add VERSION CHANGELOG.md
	@git commit -m "chore: bump version to $(NEW_VERSION)"
	@git tag -a "$(NEW_VERSION)" -m "Release $(NEW_VERSION)"
	@echo "Created new tag $(NEW_VERSION)"

release-minor: ## Bump minor version, commit, and tag
	@./scripts/version.sh minor
	$(eval NEW_VERSION = v$(shell cat VERSION))
	@./scripts/update_changelog.sh $(NEW_VERSION)
	@git add VERSION CHANGELOG.md
	@git commit -m "chore: bump version to $(NEW_VERSION)"
	@git tag -a "$(NEW_VERSION)" -m "Release $(NEW_VERSION)"
	@echo "Created new tag $(NEW_VERSION)"

release-major: ## Bump major version, commit, and tag
	@./scripts/version.sh major
	$(eval NEW_VERSION = v$(shell cat VERSION))
	@./scripts/update_changelog.sh $(NEW_VERSION)
	@git add VERSION CHANGELOG.md
	@git commit -m "chore: bump version to $(NEW_VERSION)"
	@git tag -a "$(NEW_VERSION)" -m "Release $(NEW_VERSION)"
	@echo "Created new tag $(NEW_VERSION)"

release: ## Push release commit and tags to the remote
	@git push --follow-tags

install-hooks: ## Install git pre-commit hooks
	@echo "Installing git hooks..."
	@ln -sf ../../scripts/git-hooks/pre-commit .git/hooks/pre-commit
	@echo "Done."
