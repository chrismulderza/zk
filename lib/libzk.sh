#!/usr/bin/env bash

# This file contains all shared configurations, variables, and helper functions.

# --- CONFIGURATION DEFAULTS ---
: "${ZETTEL_DIR:="$HOME/.zettelkasten"}"
: "${EDITOR:="vim"}"
: "${ZK_JOURNAL_DIR:="journal/daily"}"
: "${ZK_BOOKMARK_DIR:="resources/bookmarks"}"
: "${XDG_CONFIG_HOME:="$HOME/.config"}"
: "${ZK_TEMPLATE_DIR:="$XDG_CONFIG_HOME/zk/templates"}"

# --- PATH DEFINITIONS ---
DB_FILE="$ZETTEL_DIR/zettel.db"
TEMPLATE_DIR="$ZK_TEMPLATE_DIR"

# --- EXTERNAL TOOL DEFINITIONS ---
# Define all external tool commands here for easy testing and overriding
: "${SQLITE3:="sqlite3"}"
: "${GREP:="grep"}"
: "${SED:="sed"}"
: "${AWK:="awk"}"
: "${FIND:="find"}"
: "${HEAD:="head"}"
: "${XXD:="xxd"}"
: "${TR:="tr"}"
: "${SORT:="sort"}"
: "${BASENAME:="basename"}"
: "${UNAME:="uname"}"
: "${CUT:="cut"}"
: "${XARGS:="xargs"}"
: "${DATE:="date"}"
: "${MKDIR:="mkdir"}"
: "${CAT:="cat"}"
: "${PRINTF:="printf"}"
: "${LS:="ls"}"
: "${EVAL:="eval"}"

# Interactive tools
: "${FZF:="fzf"}"
: "${RG:="rg"}"
: "${BAT:="bat"}"
: "${VIM:="vim"}"
: "${TMUX:="tmux"}"

# Detect stat command (macOS vs Linux)
if command -v gstat &> /dev/null; then
    STAT="gstat"
    STAT_MTIME_FLAG="-c %Y"
elif [[ "$(${UNAME})" == "Darwin" ]]; then
    STAT="stat"
    STAT_MTIME_FLAG="-f %m"
else
    STAT="stat"
    STAT_MTIME_FLAG="-c %Y"
fi

# --- HELPER FUNCTIONS ---
function _generate_id() {
    while true; do
        local id; id=$(${HEAD} -c 3 /dev/urandom | ${XXD} -p)
        if ! ${FIND} "$ZETTEL_DIR" -name "${id}-*.md" -print -quit | ${GREP} -q .; then
            echo "$id"; return 0;
        fi
    done
}
function _slugify() { echo "$1" | ${TR} '[:upper:]' '[:lower:]' | ${SED} -e 's/[^a-zA-Z0-9]/-/g' | ${SED} -e ':a' -e 's/--/-/g' -e 'ta' | ${SED} -e 's/^-//' -e 's/-$//'; }
function _title_case() { local i="$1" r=""; for w in $i; do r+="${w^} "; done; echo "${r% }"; }
function _sed_escape() { echo "$1" | ${SED} -e 's/[\\/&]/\\&/g'; }

function _get_template_placeholders() {
    local template_file="$1"
    ${GREP} -o '{{[A-Z_]*}}' "$template_file" | ${SORT} -u | ${SED} 's/[{}]//g'
}

function _process_template() {
    local template_file="$1"
    local output_file="$2"
    local -n template_data=$3
    local content
    content=$(${CAT} "$template_file")
    for key in "${!template_data[@]}"; do
        local value
        value=$(_sed_escape "${template_data[$key]}")
        content=$(echo "$content" | ${SED} "s/{{${key}}}/$value/g")
    done
    echo "$content" >"$output_file"
}


# Extract YAML frontmatter into an associative array
# Usage: _extract_frontmatter <filepath> <array_name>
# Example: declare -A metadata; _extract_frontmatter "$file" metadata
function _extract_frontmatter() {
    local filepath="$1"
    local -n arr=$2

    local in_frontmatter=0
    local current_key=""
    local current_value=""
    local in_array=0

    while IFS= read -r line; do
        # Start of frontmatter
        if [[ "$line" == "---" ]] && [[ $in_frontmatter -eq 0 ]]; then
            in_frontmatter=1
            continue
        fi

        # End of frontmatter
        if [[ "$line" == "---" ]] && [[ $in_frontmatter -eq 1 ]]; then
            # Save any pending key-value
            if [[ -n "$current_key" ]]; then
                arr["$current_key"]="$current_value"
            fi
            break
        fi

        if [[ $in_frontmatter -eq 1 ]]; then
            # Handle array values (tags: [tag1, tag2] or aliases: [a1, a2])
            if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):\ *\[(.*)\]$ ]]; then
                # Save previous key if exists
                if [[ -n "$current_key" ]]; then
                    arr["$current_key"]="$current_value"
                fi
                current_key="${BASH_REMATCH[1]}"
                current_value="${BASH_REMATCH[2]}"
                in_array=0
            # Handle simple key: value
            elif [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):\ *(.*)$ ]]; then
                # Save previous key if exists
                if [[ -n "$current_key" ]]; then
                    arr["$current_key"]="$current_value"
                fi
                current_key="${BASH_REMATCH[1]}"
                current_value="${BASH_REMATCH[2]}"
                # Remove quotes (both regular and escaped)
                current_value="${current_value#\\\"}"
                current_value="${current_value%\\\"}"
                current_value="${current_value#\"}"
                current_value="${current_value%\"}"
                current_value="${current_value#\'}"
                current_value="${current_value%\'}"
                in_array=0
            fi
        fi
    done < "$filepath"
}

function _ensure_initialized() {
    if [ ! -d "$ZETTEL_DIR" ] || [ ! -f "$DB_FILE" ]; then
        echo "Error: Zettelkasten not initialized in '$ZETTEL_DIR'." >&2
        echo "Please run 'zk init' to set up your knowledge base." >&2
        exit 1
    fi
}

function db_init() {
    ${SQLITE3} "$DB_FILE" <<'EOF'
CREATE TABLE IF NOT EXISTS notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, type TEXT, path TEXT NOT NULL UNIQUE, modified_at INTEGER);
CREATE TABLE IF NOT EXISTS tags (note_id TEXT, tag TEXT, PRIMARY KEY (note_id, tag), FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS aliases (note_id TEXT, alias TEXT, PRIMARY KEY (note_id, alias), FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(note_id UNINDEXED, content, tokenize = 'porter unicode61');
CREATE TABLE IF NOT EXISTS links (source_id TEXT, target_id TEXT, PRIMARY KEY (source_id, target_id), FOREIGN KEY (source_id) REFERENCES notes(id) ON DELETE CASCADE, FOREIGN KEY (target_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS idx_notes_type ON notes(type);
EOF
}

# REWRITTEN: This function is now robust and correctly updates the backlink section.
function _update_backlinks_for_note() {
    local target_id="$1"
    if [ -z "$target_id" ]; then return; fi

    local target_path
    target_path="$ZETTEL_DIR/$(${SQLITE3} "$DB_FILE" "SELECT path FROM notes WHERE id = '$target_id'")"
    if [ ! -f "$target_path" ]; then return; fi

    # Define the markers to ensure consistency
    local start_marker="<!-- BACKLINK_START -->"
    local end_marker="<!-- BACKLINK_END -->"

    # Use a temporary file for safe, atomic "in-place" editing.
    local temp_file="${target_path}.tmp"

    # 1. Remove the old backlink block if it exists.
    # The awk script prints every line, but sets a flag to skip printing
    # when it's between the start and end markers. This preserves all original content.
    ${AWK} -v start="$start_marker" -v end="$end_marker" '
        $0 ~ start { in_block = 1; next }
        $0 ~ end   { in_block = 0; next }
        !in_block { print }
    ' "$target_path" > "$temp_file" && mv "$temp_file" "$target_path"

    # 2. Query for the current list of backlinks.
    local backlinks
    backlinks=$(${SQLITE3} "$DB_FILE" "SELECT n.title FROM links l JOIN notes n ON l.source_id = n.id WHERE l.target_id = '$target_id' ORDER BY n.title ASC;")

    # 3. If backlinks exist, generate and append the new block.
    if [ -n "$backlinks" ]; then
        # Use a command group with redirection to build the multi-line string.
        local backlink_section
        backlink_section=$(
            echo "" # Ensures a blank line before the block
            echo "$start_marker"
            echo "## Backlinks"
            (
                IFS=$'\n'
                for title in $backlinks; do
                    echo "- [[$title]]"
                done
            )
            echo "$end_marker"
        )
        # Append the new, complete block to the file.
        echo "$backlink_section" >> "$target_path"
    fi
}

function _index_file() {
    local filepath="$1"
    local update_backlinks="${2:-true}"

    # Extract frontmatter using the generic function
    declare -A frontmatter
    _extract_frontmatter "$filepath" frontmatter

    local id="${frontmatter[id]}"
    if [ -z "$id" ]; then echo "Warning: No 'id:' field found in $filepath. Skipping file." >&2; return; fi

    local type="${frontmatter[type]:-note}"
    echo "Indexing: $filepath (ID: $id, Type: $type)"

    local title="${frontmatter[title]:-}"
    local tags_raw="${frontmatter[tags]:-}"
    local aliases_raw="${frontmatter[aliases]:-}"
    local uri="${frontmatter[uri]:-}"

    # Process tags: remove quotes and commas, convert to space-separated
    local tags; tags=$(echo "$tags_raw" | ${SED} 's/"//g; s/,/ /g')

    # Process aliases: remove quotes, convert commas to newlines for iteration
    local aliases; aliases=$(echo "$aliases_raw" | ${SED} 's/"//g' | ${TR} ',' '\n')

    # REVISED: Correctly extract the body by stopping before the backlink block.
    # This ensures backlink content is not indexed in full-text search.
    local body; body=$(${AWK} 'NR>1 && /---/ {p=0} p; /---/ {p=1}' "$filepath" | ${AWK} '// { exit } 1')

    local old_targets; old_targets=$(${SQLITE3} "$DB_FILE" "SELECT target_id FROM links WHERE source_id = '$id'")
    
    local modified_at
    modified_at=$(${STAT} ${STAT_MTIME_FLAG} "$filepath")
    
    local zettel_dir_with_slash="${ZETTEL_DIR%/}/"
    local relative_path="${filepath#$zettel_dir_with_slash}"

    ${SQLITE3} "$DB_FILE" <<EOF
BEGIN;
REPLACE INTO notes (id, title, type, path, modified_at) VALUES ('$id', '$title', '$type', '$relative_path', $modified_at);
DELETE FROM tags WHERE note_id = '$id';
DELETE FROM aliases WHERE note_id = '$id';
DELETE FROM links WHERE source_id = '$id';
COMMIT;
EOF
    for tag in $tags; do ${SQLITE3} "$DB_FILE" "INSERT INTO tags (note_id, tag) VALUES ('$id', '$tag');"; done
    ( IFS=$'\n'; for alias in $aliases; do alias=$(echo "$alias" | ${SED} 's/^[ \t]*//;s/[ \t]*$//'); if [ -n "$alias" ]; then ${SQLITE3} "$DB_FILE" "INSERT INTO aliases (note_id, alias) VALUES ('$id', '${alias//\'/\'\'}');"; fi; done; )
    
    local all_targets; all_targets=$(( ${SED} -n 's/.*\[\[\([^]]*\)\]\].*/\1/p' "$filepath"; ${SED} -n 's/.*](\([^)]*\)).*/\1/p' "$filepath"; ) | ${SORT} -u)
    local new_targets=""
    ( IFS=$'\n'; for raw_target in $all_targets; do
        local target=$(${BASENAME} "$raw_target" .md)
        # TODO: This is too complicated. Just extract the id from the metadata.
        local target_id=$(${SQLITE3} "$DB_FILE" "SELECT id FROM notes WHERE id = '${target//\'/\'\'}' UNION SELECT id FROM notes WHERE title = '${target//\'/\'\'}' UNION SELECT note_id FROM aliases WHERE alias = '${target//\'/\'\'}' LIMIT 1;")
        if [ -n "$target_id" ]; then
            ${SQLITE3} "$DB_FILE" "INSERT OR IGNORE INTO links (source_id, target_id) VALUES ('$id', '$target_id');"
            new_targets+="${target_id}\n"
        fi
    done )

    local full_content="$title $uri $tags $(echo "$aliases" | ${TR} '\n' ' ') $body"
    ${SQLITE3} "$DB_FILE" "DELETE FROM notes_fts WHERE note_id = '$id'; INSERT INTO notes_fts (note_id, content) VALUES ('$id', '${full_content//\'/\'\'}');"

    if [[ "$update_backlinks" == "true" ]]; then
        local affected_targets; affected_targets=$(echo -e "${old_targets}\n${new_targets}" | ${SORT} -u)
        ( IFS=$'\n'; for target_id in $affected_targets; do
            _update_backlinks_for_note "$target_id"
        done )
    fi
}
