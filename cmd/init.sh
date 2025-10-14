#!/usr/bin/env bash

#
# Contains the implementation for the 'init' command.
#

function _help() {
    echo "init [dir]        Initialize a new notebook in the given directory (or current dir)."
}

function cmd_init() {
    local init_dir="${1:-.}"
    
    # If a directory is specified, use its absolute path.
    if [ "$init_dir" != "." ]; then
        mkdir -p "$init_dir"
        ZETTEL_DIR=$(cd "$init_dir" && pwd)
    else
        ZETTEL_DIR=$(pwd)
    fi

    if [ -d "$ZETTEL_DIR/.zk" ]; then
        echo "Notebook already initialized at '$ZETTEL_DIR'."
        return
    fi

    echo "Initializing new notebook at '$ZETTEL_DIR'..."
    
    # Create the core '.zk' hidden directory.
    mkdir -p "$ZETTEL_DIR/.zk"
    
    # Create the main data directories in the notebook root.
    mkdir -p "$ZETTEL_DIR/$ZK_JOURNAL_DIR"
    mkdir -p "$ZETTEL_DIR/$ZK_BOOKMARK_DIR"
    echo "Created data directory structure in '$ZETTEL_DIR'."

    # Define the DB file path now that ZETTEL_DIR is confirmed.
    DB_FILE="$ZETTEL_DIR/.zk/zettel.db"
    
    # Create and initialize the database.
    touch "$DB_FILE"
    db_init
    echo "Database initialized at '$DB_FILE'."

    # Create notebook-specific templates and config directories.
    mkdir -p "$ZETTEL_DIR/.zk/templates"
    echo "Created local templates directory at '$ZETTEL_DIR/.zk/templates'."

    local notebook_config_file="$ZETTEL_DIR/.zk/config.sh"
    if [ ! -f "$notebook_config_file" ]; then
        cat >"$notebook_config_file" <<EOM
# --- Notebook Configuration File ---
# This file is sourced by 'zk' to set notebook-specific preferences.
# Settings here will override your global settings in ~/.config/zk/config.sh.

# Your preferred text editor for this notebook.
# export EDITOR="vim"

# --- Directory Paths (relative to notebook root) ---

# Directory for daily journal entries.
# export ZK_JOURNAL_DIR="journal"

# Directory for saved bookmarks.
# export ZK_BOOKMARK_DIR="resources/bookmarks"
EOM
        echo "Created notebook configuration file at '$notebook_config_file'."
    fi
    
    echo ""
    echo "Initialization complete. You can now use zk commands in this directory."
}
