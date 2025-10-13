# Makefile for zk - Zettelkasten knowledge management system

PREFIX ?= $(HOME)/.local
INSTALL_DIR = $(PREFIX)/zk
BIN_DIR = $(PREFIX)/bin
COMPLETION_DIR = $(HOME)/.bash_completion.d

.PHONY: install uninstall clean test

install:
	@echo "Installing zk to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(COMPLETION_DIR)

	# Copy main executable
	@cp -f zk $(INSTALL_DIR)/zk
	@chmod +x $(INSTALL_DIR)/zk

	# Copy command files
	@cp -r cmd $(INSTALL_DIR)/

	# Copy library files
	@cp -r lib $(INSTALL_DIR)/

	# Create symlink in bin directory
	@ln -sf $(INSTALL_DIR)/zk $(BIN_DIR)/zk

	# Generate and install completion script
	@$(INSTALL_DIR)/zk completion > $(COMPLETION_DIR)/zk

	@echo ""
	@echo "Installation complete!"
	@echo "  - Executable: $(INSTALL_DIR)/zk"
	@echo "  - Symlink: $(BIN_DIR)/zk"
	@echo "  - Completion: $(COMPLETION_DIR)/zk"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Ensure $(BIN_DIR) is in your PATH"
	@echo "  2. Add to ~/.bashrc: source ~/.bash_completion.d/zk"
	@echo "  3. Run: zk init"

uninstall:
	@echo "Uninstalling zk..."
	@rm -f $(BIN_DIR)/zk
	@rm -rf $(INSTALL_DIR)
	@rm -f $(COMPLETION_DIR)/zk
	@echo "Uninstall complete!"

clean:
	@echo "Nothing to clean (no build artifacts)"

test:
	@echo "Running unit tests..."
	@bats test/unit/
