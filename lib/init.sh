#!/usr/bin/env bash
function cmd_init() {
    if [ -d "$ZETTEL_DIR" ] && [ -f "$DB_FILE" ]; then
        echo "Zettelkasten already initialized at '$ZETTEL_DIR'."
        return
    fi

    echo "Initializing Zettelkasten at '$ZETTEL_DIR'..."
    # Create the main data directories
    mkdir -p "$ZETTEL_DIR"
    mkdir -p "$ZETTEL_DIR/$ZK_JOURNAL_DIR"
    mkdir -p "$ZETTEL_DIR/$ZK_BOOKMARK_DIR"
    echo "Created data directory structure in '$ZETTEL_DIR'."

    # Create the database file
    touch "$DB_FILE"
    db_init
    echo "Database initialized at '$DB_FILE'."

    # Create the configuration directory and default config file
    local config_dir
    config_dir=$(dirname "$ZK_CONFIG_FILE")
    mkdir -p "$config_dir"
    
    # MODIFIED: Also create the template directory inside the config folder
    mkdir -p "$ZK_TEMPLATE_DIR"
    echo "Created templates directory at '$ZK_TEMPLATE_DIR'."

    if [ ! -f "$ZK_CONFIG_FILE" ]; then
        # MODIFIED: Added ZK_TEMPLATE_DIR to the default config file.
        cat > "$ZK_CONFIG_FILE" <<EOF
# --- ZK Configuration File ---
# This file is sourced by the 'zk' script to set user preferences.
# Uncomment and edit the lines below to override the defaults.

# The root directory for your Zettelkasten.
# export ZETTEL_DIR="\$HOME/.zettelkasten"

# Your preferred text editor.
# export EDITOR="vim"

# --- Directory Paths ---

# Directory for daily journal entries (relative to ZETTEL_DIR).
# export ZK_JOURNAL_DIR="journal/daily"

# Directory for saved bookmarks (relative to ZETTEL_DIR).
# export ZK_BOOKMARK_DIR="resources/bookmarks"

# Absolute path to the directory for note templates.
# export ZK_TEMPLATE_DIR="\$XDG_CONFIG_HOME/zk/templates"
EOF
        echo "Created default configuration file at '$ZK_CONFIG_FILE'."
        echo "You can edit this file to customize zk's behavior."
    fi
    echo ""
    echo "Initialization complete. You can now start using zk commands."
}