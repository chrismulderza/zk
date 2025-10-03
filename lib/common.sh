#!/usr/bin/env bash

# This file contains all shared configurations, variables, and helper functions.
# It sets fallback defaults if they are not defined in the user's config file.

# --- CONFIGURATION DEFAULTS ---
: "${ZETTEL_DIR:="$HOME/.zettelkasten"}"
: "${EDITOR:="vim"}"

# Directory paths relative to ZETTEL_DIR
: "${ZK_JOURNAL_DIR:="journal/daily"}"
: "${ZK_BOOKMARK_DIR:="resources/bookmarks"}"

# MODIFIED: Template directory is now in the config folder by default.
: "${XDG_CONFIG_HOME:="$HOME/.config"}"
: "${ZK_TEMPLATE_DIR:="$XDG_CONFIG_HOME/zk/templates"}"

# --- PATH DEFINITIONS ---
DB_FILE="$ZETTEL_DIR/zettel.db"
TEMPLATE_DIR="$ZK_TEMPLATE_DIR" # This now points to the new location

# --- HELPER FUNCTIONS ---
function _generate_id() { date +"%Y%m%d%H%M%S"; }
function _slugify() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-zA-Z0-9]/-/g' -e 's/--\+/-/g' -e 's/^-//' -e 's/-$//'; }
function _title_case() { local i="$1" r=""; for w in $i; do r+="${w^} "; done; echo "${r% }"; }
function _sed_escape() { echo "$1" | sed -e 's/[\\/&]/\\&/g'; }

function _ensure_initialized() {
    if [ ! -d "$ZETTEL_DIR" ] || [ ! -f "$DB_FILE" ]; then
        echo "Error: Zettelkasten not initialized in '$ZETTEL_DIR'." >&2
        echo "Please run 'zk init' to set up your knowledge base." >&2
        exit 1
    fi
}

function db_init() {
    sqlite3 "$DB_FILE" <<'EOF'
CREATE TABLE IF NOT EXISTS notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, type TEXT, path TEXT NOT NULL UNIQUE, modified_at INTEGER);
CREATE TABLE IF NOT EXISTS tags (note_id TEXT, tag TEXT, PRIMARY KEY (note_id, tag), FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS aliases (note_id TEXT, alias TEXT, PRIMARY KEY (note_id, alias), FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(note_id UNINDEXED, content, tokenize = 'porter unicode61');
CREATE INDEX IF NOT EXISTS idx_notes_type ON notes(type);
EOF
}

function _index_file() {
    local filepath="$1"
    local id; id=$(grep -m 1 '^id:' "$filepath" | sed 's/^id: *//; s/"//g; s/'"'"'//g')
    if [ -z "$id" ]; then echo "Warning: No 'id:' field found in $filepath. Skipping file." >&2; return; fi
    local type; type=$(grep -m 1 '^type:' "$filepath" | sed 's/^type: *//; s/"//g; s/'"'"'//g'); : "${type:="note"}"
    echo "Indexing: $filepath (ID: $id, Type: $type)"
    local title; title=$(grep -m 1 '^title:' "$filepath" | sed 's/^title: *//; s/"//g; s/'"'"'//g'); : "${title:=""}"
    local tags; tags=$(grep -m 1 '^tags:' "$filepath" | sed 's/^tags: *//; s/\[//; s/\]//; s/,//g'); : "${tags:=""}"
    local aliases; aliases=$(grep -m 1 '^aliases:' "$filepath" | sed -e 's/^aliases: *\[//' -e 's/\]$//' -e 's/"//g' | tr ',' '\n'); : "${aliases:=""}"
    local uri; uri=$(grep -m 1 '^uri:' "$filepath" | sed 's/^uri: *//'); : "${uri:=""}"
    local description; description=$(grep -m 1 '^description:' "$filepath" | sed 's/^description: *//'); : "${description:=""}"
    local body; body=$(awk 'NR>1 && /---/ {p=0} p; /---/ {p=1}' "$filepath")
    local modified_at
    if command -v gstat &> /dev/null; then modified_at=$(gstat -c %Y "$filepath"); elif [[ "$(uname)" == "Darwin" ]]; then modified_at=$(stat -f %m "$filepath"); else modified_at=$(stat -c %Y "$filepath"); fi
    local zettel_dir_with_slash="${ZETTEL_DIR%/}/"
    local relative_path="${filepath#$zettel_dir_with_slash}"
    sqlite3 "$DB_FILE" <<EOF
BEGIN;
REPLACE INTO notes (id, title, type, path, modified_at) VALUES ('$id', '$title', '$type', '$relative_path', $modified_at);
DELETE FROM tags WHERE note_id = '$id';
DELETE FROM aliases WHERE note_id = '$id';
COMMIT;
EOF
    for tag in $tags; do sqlite3 "$DB_FILE" "INSERT INTO tags (note_id, tag) VALUES ('$id', '$tag');"; done
    ( IFS=$'\n'; for alias in $aliases; do alias=$(echo "$alias" | sed 's/^[ \t]*//;s/[ \t]*$//'); if [ -n "$alias" ]; then sqlite3 "$DB_FILE" "INSERT INTO aliases (note_id, alias) VALUES ('$id', '${alias//\'/\'\'}');"; fi; done; )
    local full_content="$title $uri $description $tags $(echo "$aliases" | tr '\n' ' ') $body"
    sqlite3 "$DB_FILE" "DELETE FROM notes_fts WHERE note_id = '$id'; INSERT INTO notes_fts (note_id, content) VALUES ('$id', '${full_content//\'/\'\'}');"
}