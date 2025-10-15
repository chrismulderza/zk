#!/usr/bin/env bash

# This file contains all shared configurations, variables, and helper functions.

# --- CONFIGURATION DEFAULTS ---
# Note: ZETTEL_DIR is now set in the main 'zk' script.
: "${EDITOR:="nvim"}"
: "${ZK_JOURNAL_DIR:="journal"}"
: "${ZK_BOOKMARK_DIR:="resources/bookmarks"}"

# --- PATH DEFINITIONS ---
# These paths are relative to the notebook root (ZETTEL_DIR).
DB_FILE="$ZETTEL_DIR/.zk/zettel.db"

# Template directory resolution:
# 1. Prioritize notebook-specific templates.
# 2. Fall back to global XDG config directory.
if [ -d "$ZETTEL_DIR/.zk/templates" ]; then
    TEMPLATE_DIR="$ZETTEL_DIR/.zk/templates"
else
    : "${XDG_CONFIG_HOME:="$HOME/.config"}"
    TEMPLATE_DIR="$XDG_CONFIG_HOME/zk/templates"
fi

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
#: "${VIM:="$EDITOR"}"
: "${TMUX:="tmux"}"

# Detect stat command (macOS vs Linux)
if command -v gstat &>/dev/null; then
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

# Checks if an ID exists in the database.
#
# Arguments:
#   $1: The ID to check.
#
# Returns:
#   0 if ID exists, 1 if not.
function _id_exists_in_db() {
    local id="$1"
    local count
    
    count=$(${SQLITE3} "$DB_FILE" "SELECT COUNT(*) FROM notes WHERE id = '$id'" 2>/dev/null)
    [ "$count" -gt 0 ]
}

# Generates a short, unique ID for a new note.
# The function reads 3 bytes from /dev/urandom, converts them to a hex
# string, and checks if a note with that ID already exists. It repeats
# until a unique ID is found.
#
# Outputs:
#   A 6-character unique hexadecimal string.
function _generate_id() {
    while true; do
        local id
        id=$(${HEAD} -c 3 /dev/urandom | ${XXD} -p)
        
        if [ -f "$DB_FILE" ]; then
            if ! _id_exists_in_db "$id"; then
                echo "$id"
                return 0
            fi
        else
            if ! ${FIND} "$ZETTEL_DIR" -name "${id}-*.md" -print -quit | ${GREP} -q .; then
                echo "$id"
                return 0
            fi
        fi
    done
}

# Converts a string into a URL-friendly slug.
# Replaces spaces and special characters with hyphens, converts to
# lowercase, and removes leading/trailing hyphens.
#
# Arguments:
#   $1: The string to slugify.
#
# Outputs:
#   The slugified string.
function _slugify() {
    echo "$1" |
        ${TR} '[:upper:]' '[:lower:]' |
        ${SED} -e 's/[^a-zA-Z0-9]/-/g' |
        ${SED} -e ':a' -e 's/--/-/g' -e 'ta' |
        ${SED} -e 's/^-//' -e 's/-$//'
}

# Converts a string to Title Case.
#
# Arguments:
#   $1: The string to convert.
#
# Outputs:
#   The string in Title Case.
function _title_case() {
    local i="$1"
    local r=""
    for w in $i; do
        r+="${w^} "
    done
    echo "${r% }"
}

# Escapes a string for use in a sed replacement pattern.
#
# Arguments:
#   $1: The string to escape.
#
# Outputs:
#   The escaped string.
function _sed_escape() {
    echo "$1" | ${SED} -e 's/[\\/&]/\\&/g'
}

# Checks if a given string is an external URI.
#
# Arguments:
#   $1: The URI to check.
#
# Returns:
#   0 if it's an external URI, 1 otherwise.
function _is_external_uri() {
    local uri="$1"

    if [[ "$uri" =~ ^https?:// ]] ||
        [[ "$uri" =~ ^ftp:// ]] ||
        [[ "$uri" =~ ^ftps:// ]] ||
        [[ "$uri" =~ ^mailto: ]] ||
        [[ "$uri" =~ ^file:// ]] ||
        [[ "$uri" == /* ]]; then
        return 0
    fi
    return 1
}

# Calculates the relative path from one directory to another file.
#
# Arguments:
#   $1: The absolute path of the starting directory.
#   $2: The absolute path of the target file.
#
# Outputs:
#   The relative path from the first argument to the second.
function _calculate_relative_path() {
    local from_dir="$1"
    local to_file="$2"

    from_dir="${from_dir%/}"
    to_file="${to_file%/}"

    local from_abs="$from_dir"
    local to_abs="$to_file"

    IFS='/' read -ra from_parts <<<"${from_abs#/}"
    IFS='/' read -ra to_parts <<<"${to_abs#/}"

    local common=0
    local max_common=$((${#from_parts[@]} < ${#to_parts[@]} ? ${#from_parts[@]} : ${#to_parts[@]}))

    for ((i = 0; i < max_common; i++)); do
        if [ "${from_parts[$i]}" = "${to_parts[$i]}" ]; then
            ((common++))
        else
            break
        fi
    done

    local result=""

    local ups=$((${#from_parts[@]} - common))
    for ((i = 0; i < ups; i++)); do
        if [ -z "$result" ]; then
            result=".."
        else
            result="$result/.."
        fi
    done

    for ((i = common; i < ${#to_parts[@]}; i++)); do
        if [ -z "$result" ]; then
            result="${to_parts[$i]}"
        else
            result="$result/${to_parts[$i]}"
        fi
    done

    if [ -z "$result" ]; then
        result="."
    fi

    echo "$result"
}

# Escapes special characters for sed patterns in link updates.
#
# Arguments:
#   $1: The string to escape.
#
# Outputs:
#   The escaped string.
function _escape_for_link_replacement() {
    echo "$1" | ${SED} 's/[\/&]/\\&/g'
}

# Updates a Markdown link in a file.
#
# Arguments:
#   $1: The path to the file to update.
#   $2: The old link target.
#   $3: The new link target.
function _update_link_in_file() {
    local filepath="$1"
    local old_link="$2"
    local new_link="$3"
    local temp_file="${filepath}.linkupdate.tmp"

    local old_escaped
    local new_escaped
    old_escaped=$(_escape_for_link_replacement "$old_link")
    new_escaped=$(_escape_for_link_replacement "$new_link")

    ${SED} "s/]($old_escaped)/]($new_escaped)/g" "$filepath" >"$temp_file" &&
        mv "$temp_file" "$filepath"

    echo "Updated link in $filepath: $old_link -> $new_link"
}

# Extracts all unique {{PLACEHOLDER}} variables from a template file.
#
# Arguments:
#   $1: The path to the template file.
#
# Outputs:
#   A newline-separated list of unique placeholder names (without brackets).
function _get_template_placeholders() {
    local template_file="$1"

    ${GREP} -o '{{[A-Z_]*}}' "$template_file" |
        ${SORT} -u |
        ${SED} 's/[{}]//g'
}

# Replaces a single placeholder in content with its value.
#
# Arguments:
#   $1: The content string.
#   $2: The placeholder key (without braces).
#   $3: The replacement value (already escaped).
#
# Outputs:
#   The content with the placeholder replaced.
function _replace_placeholder() {
    local content="$1"
    local key="$2"
    local value="$3"

    echo "$content" | ${SED} "s/{{${key}}}/$value/g"
}

# Processes a template file, replacing placeholders with values from an
# associative array.
#
# Arguments:
#   $1: The path to the template file.
#   $2: The path for the output file.
#   $3: The name of the associative array containing placeholder values.
function _process_template() {
    local template_file="$1"
    local output_file="$2"
    local -n template_data=$3

    local content
    content=$(${CAT} "$template_file")

    for key in "${!template_data[@]}"; do
        local value
        value=$(_sed_escape "${template_data[$key]}")
        content=$(_replace_placeholder "$content" "$key" "$value")
    done

    echo "$content" >"$output_file"
}

# Removes surrounding quotes from a string (both regular and escaped).
#
# Arguments:
#   $1: The string to unquote.
#
# Outputs:
#   The string without surrounding quotes.
function _remove_quotes() {
    local value="$1"

    value="${value#\\\"}"
    value="${value%\\\"}"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"

    echo "$value"
}

# Saves the current key-value pair into the frontmatter array.
#
# Arguments:
#   $1: The key to save.
#   $2: The value to save.
#   $3: The name of the associative array.
function _save_frontmatter_pair() {
    local key="$1"
    local value="$2"
    local -n target_arr=$3

    if [[ -n "$key" ]]; then
        target_arr["$key"]="$value"
    fi
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

    while IFS= read -r line; do
        if [[ "$line" == "---" ]] && [[ $in_frontmatter -eq 0 ]]; then
            in_frontmatter=1
            continue
        fi

        if [[ "$line" == "---" ]] && [[ $in_frontmatter -eq 1 ]]; then
            _save_frontmatter_pair "$current_key" "$current_value" arr
            break
        fi

        if [[ $in_frontmatter -eq 1 ]]; then
            if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):\ *\[(.*)\]$ ]]; then
                _save_frontmatter_pair "$current_key" "$current_value" arr
                current_key="${BASH_REMATCH[1]}"
                current_value="${BASH_REMATCH[2]}"
            elif [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):\ *(.*)$ ]]; then
                _save_frontmatter_pair "$current_key" "$current_value" arr
                current_key="${BASH_REMATCH[1]}"
                current_value=$(_remove_quotes "${BASH_REMATCH[2]}")
            fi
        fi
    done <"$filepath"
}

# Checks if a file has frontmatter.
#
# Arguments:
#   $1: The path to the file.
#
# Returns:
#   0 if file has frontmatter, 1 otherwise.
function _has_frontmatter() {
    local filepath="$1"
    local first_line

    first_line=$(${HEAD} -1 "$filepath")
    [[ "$first_line" == "---" ]]
}

# Inserts ID into existing frontmatter.
#
# Arguments:
#   $1: The path to the note file.
#   $2: The ID to insert.
#   $3: The temporary file path.
function _insert_id_into_existing_frontmatter() {
    local filepath="$1"
    local id="$2"
    local temp_file="$3"

    ${AWK} -v id="$id" '
        NR == 1 { print; next }
        NR == 2 && !inserted { print "id: \"" id "\""; inserted=1 }
        { print }
    ' "$filepath" >"$temp_file" && mv "$temp_file" "$filepath"
}

# Creates new frontmatter with ID.
#
# Arguments:
#   $1: The path to the note file.
#   $2: The ID to insert.
#   $3: The temporary file path.
function _create_frontmatter_with_id() {
    local filepath="$1"
    local id="$2"
    local temp_file="$3"

    local original_content
    original_content=$(${CAT} "$filepath")

    {
        echo "---"
        echo "id: \"$id\""
        echo "---"
        echo "$original_content"
    } >"$temp_file" && mv "$temp_file" "$filepath"
}

# Inserts an 'id' field into the frontmatter of a note if it doesn't exist.
# If the file has no frontmatter, it creates it.
#
# Arguments:
#   $1: The path to the note file.
#   $2: The ID to insert.
function _insert_id_into_frontmatter() {
    local filepath="$1"
    local id="$2"
    local temp_file="${filepath}.tmp"

    if [ ! -f "$filepath" ]; then
        echo "Error: File not found: $filepath" >&2
        return 1
    fi

    if _has_frontmatter "$filepath"; then
        _insert_id_into_existing_frontmatter "$filepath" "$id" "$temp_file"
    else
        _create_frontmatter_with_id "$filepath" "$id" "$temp_file"
    fi
}

# Ensures that the Zettelkasten has been initialized.
# Exits with an error if the main directory or database file is not found.
function _ensure_initialized() {
    if [ ! -d "$ZETTEL_DIR/.zk" ] || [ ! -f "$DB_FILE" ]; then
        echo "Error: Notebook not initialized in '$ZETTEL_DIR'." >&2
        echo "Please run 'zk init' to set up this directory as a notebook." >&2
        exit 1
    fi
}

# Initializes the SQLite database schema.
# Creates all necessary tables and indexes if they don't already exist.
function db_init() {
    ${SQLITE3} "$DB_FILE" <<'EOM'
CREATE TABLE IF NOT EXISTS notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, type TEXT, path TEXT NOT NULL UNIQUE, modified_at INTEGER);
CREATE TABLE IF NOT EXISTS tags (note_id TEXT, tag TEXT, PRIMARY KEY (note_id, tag), FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS aliases (note_id TEXT, alias TEXT, PRIMARY KEY (note_id, alias), FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(note_id UNINDEXED, content, tokenize = 'porter unicode61');
CREATE TABLE IF NOT EXISTS links (source_id TEXT, target_id TEXT, PRIMARY KEY (source_id, target_id), FOREIGN KEY (source_id) REFERENCES notes(id) ON DELETE CASCADE, FOREIGN KEY (target_id) REFERENCES notes(id) ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS idx_notes_type ON notes(type);
EOM
}

# Gets the file path for a note by its ID.
#
# Arguments:
#   $1: The note ID.
#
# Outputs:
#   The full path to the note file, or empty if not found.
function _get_note_path_by_id() {
    local note_id="$1"
    local relative_path

    relative_path=$(${SQLITE3} "$DB_FILE" "SELECT path FROM notes WHERE id = '$note_id'")
    if [ -n "$relative_path" ]; then
        echo "$ZETTEL_DIR/$relative_path"
    fi
}

# Removes the old backlink block from a file.
#
# Arguments:
#   $1: The path to the file.
#   $2: The start marker.
#   $3: The end marker.
function _remove_backlink_block() {
    local filepath="$1"
    local start_marker="$2"
    local end_marker="$3"
    local temp_file="${filepath}.tmp"

    ${AWK} -v start="$start_marker" -v end="$end_marker" '
        $0 ~ start { in_block = 1; next }
        $0 ~ end   { in_block = 0; next }
        !in_block { print }
    ' "$filepath" >"$temp_file" && mv "$temp_file" "$filepath"
}

# Queries the database for backlinks to a note.
#
# Arguments:
#   $1: The target note ID.
#
# Outputs:
#   Pipe-separated list of "path|title" for each backlink.
function _query_backlinks() {
    local target_id="$1"

    ${SQLITE3} -separator '|' "$DB_FILE" \
        "SELECT n.path, n.title FROM links l JOIN notes n ON l.source_id = n.id WHERE l.target_id = '$target_id' ORDER BY n.title ASC;"
}

# Formats a single backlink entry as markdown.
#
# Arguments:
#   $1: The backlink entry in "path|title" format.
#
# Outputs:
#   Markdown list item for the backlink.
function _format_backlink_entry() {
    local backlink_entry="$1"
    local bl_path
    local bl_title

    bl_path=$(echo "$backlink_entry" | ${CUT} -d'|' -f1)
    bl_title=$(echo "$backlink_entry" | ${CUT} -d'|' -f2)

    echo "- [$bl_title]($bl_path)"
}

# Generates the backlinks section content.
#
# Arguments:
#   $1: The start marker.
#   $2: The end marker.
#   $3: The backlinks data (newline-separated list).
#
# Outputs:
#   The complete backlinks section.
function _generate_backlinks_section() {
    local start_marker="$1"
    local end_marker="$2"
    local backlinks="$3"

    echo ""
    echo "$start_marker"
    echo "## Backlinks"

    IFS=$'\n'
    for backlink_entry in $backlinks; do
        _format_backlink_entry "$backlink_entry"
    done

    echo "$end_marker"
}

# Updates the '## Backlinks' section at the end of a note.
# It first removes any existing backlink section and then appends a new,
# updated one based on the current links in the database.
#
# Arguments:
#   $1: The ID of the note to update.
function _update_backlinks_for_note() {
    local target_id="$1"

    if [ -z "$target_id" ]; then
        return
    fi

    local target_path
    target_path=$(_get_note_path_by_id "$target_id")

    if [ ! -f "$target_path" ]; then
        return
    fi

    local start_marker="<!-- BACKLINK_START -->"
    local end_marker="<!-- BACKLINK_END -->"

    _remove_backlink_block "$target_path" "$start_marker" "$end_marker"

    local backlinks
    backlinks=$(_query_backlinks "$target_id")

    if [ -n "$backlinks" ]; then
        local backlink_section
        backlink_section=$(_generate_backlinks_section "$start_marker" "$end_marker" "$backlinks")
        echo "$backlink_section" >>"$target_path"
    fi
}

# Ensures a note has an ID, generating one if needed.
#
# Arguments:
#   $1: The file path.
#   $2: The name of the frontmatter associative array.
#
# Outputs:
#   The note ID.
function _ensure_note_has_id() {
    local filepath="$1"
    local -n fm=$2

    local id="${fm[id]}"
    if [ -z "$id" ]; then
        id=$(_generate_id)
        _insert_id_into_frontmatter "$filepath" "$id"
        echo "Generated and inserted ID '$id' for $filepath" >&2
        fm[id]="$id"
    fi

    echo "$id"
}

# Normalizes raw tags from frontmatter into space-separated format.
#
# Arguments:
#   $1: Raw tags string from frontmatter.
#
# Outputs:
#   Space-separated tags.
function _normalize_tags() {
    echo "$1" | ${SED} 's/"//g; s/,/ /g'
}

# Normalizes raw aliases from frontmatter into newline-separated format.
#
# Arguments:
#   $1: Raw aliases string from frontmatter.
#
# Outputs:
#   Newline-separated aliases.
function _normalize_aliases() {
    echo "$1" | ${SED} 's/"//g' | ${TR} ',' '\n'
}

# Extracts the note body (content after frontmatter).
#
# Arguments:
#   $1: The file path.
#
# Outputs:
#   The note body content.
function _extract_note_body() {
    ${AWK} 'p;/^---$/{p=NR>1}' "$1"
}

# Gets old link targets for a note from the database.
#
# Arguments:
#   $1: The note ID.
#
# Outputs:
#   Newline-separated list of target IDs.
function _get_old_link_targets() {
    ${SQLITE3} "$DB_FILE" "SELECT target_id FROM links WHERE source_id = '$1'"
}

# Gets the file modification time.
#
# Arguments:
#   $1: The file path.
#
# Outputs:
#   Unix timestamp of modification time.
function _get_file_mtime() {
    ${STAT} "${STAT_MTIME_FLAG}" "$1"
}

# Converts absolute path to relative path from ZETTEL_DIR.
#
# Arguments:
#   $1: The absolute file path.
#
# Outputs:
#   Relative path from ZETTEL_DIR.
function _get_relative_path_from_zettel_dir() {
    local filepath="$1"
    local zettel_dir_with_slash="${ZETTEL_DIR%/}/"
    echo "${filepath#"$zettel_dir_with_slash"}"
}

# Updates the notes table with basic metadata.
#
# Arguments:
#   $1: Note ID.
#   $2: Title.
#   $3: Type.
#   $4: Relative path.
#   $5: Modified timestamp.
function _update_notes_table() {
    local id="$1"
    local title="$2"
    local type="$3"
    local relative_path="$4"
    local modified_at="$5"

    ${SQLITE3} "$DB_FILE" <<EOM
BEGIN;
REPLACE INTO notes (id, title, type, path, modified_at) VALUES ('$id', '$title', '$type', '$relative_path', $modified_at);
DELETE FROM tags WHERE note_id = '$id';
DELETE FROM aliases WHERE note_id = '$id';
DELETE FROM links WHERE source_id = '$id';
COMMIT;
EOM
}

# Inserts tags into the database for a note.
#
# Arguments:
#   $1: Note ID.
#   $2: Space-separated tags.
function _insert_tags() {
    local note_id="$1"
    local tags="$2"

    for tag in $tags; do
        ${SQLITE3} "$DB_FILE" "INSERT INTO tags (note_id, tag) VALUES ('$note_id', '$tag');"
    done
}

# Inserts aliases into the database for a note.
#
# Arguments:
#   $1: Note ID.
#   $2: Newline-separated aliases.
function _insert_aliases() {
    local note_id="$1"
    local aliases="$2"

    IFS=$'\n'
    for alias in $aliases; do
        alias=$(echo "$alias" | ${SED} 's/^[ \t]*//;s/[ \t]*$//')
        if [ -n "$alias" ]; then
            ${SQLITE3} "$DB_FILE" "INSERT INTO aliases (note_id, alias) VALUES ('$note_id', '${alias//\'/\'\'}');"
        fi
    done
}

# Extracts all link targets from a file.
#
# Arguments:
#   $1: The file path.
#
# Outputs:
#   Unique list of link targets.
function _extract_all_link_targets() {
    local filepath="$1"

    {
        ${SED} -n 's/.*\[\[\([^]]*\)\]\].*/\1/p' "$filepath"
        ${SED} -n 's/.*](\([^)]*\)).*/\1/p' "$filepath"
    } | ${SORT} -u
}

# Strips ID prefix from filename basename.
#
# Arguments:
#   $1: The file path.
#
# Outputs:
#   Basename without ID prefix and .md extension.
function _strip_id_prefix_from_basename() {
    ${BASENAME} "$1" .md | ${SED} 's/^[a-f0-9]\{6\}-//'
}

# Finds a note file by its basename (without ID prefix).
#
# Arguments:
#   $1: Target basename to search for.
#
# Outputs:
#   Full path to the found file, or empty if not found.
function _find_file_by_basename() {
    local target="$1"

    ${FIND} "$ZETTEL_DIR" -type f -name "*.md" | while read -r potential_file; do
        local basename_without_id
        basename_without_id=$(_strip_id_prefix_from_basename "$potential_file")
        if [ "$basename_without_id" = "$target" ]; then
            echo "$potential_file"
            break
        fi
    done
}

# Looks up a note ID by various identifiers.
#
# Arguments:
#   $1: The identifier (ID, title, or alias).
#
# Outputs:
#   The note ID if found, or empty string.
function _lookup_note_id() {
    local identifier="$1"

    ${SQLITE3} "$DB_FILE" "SELECT id FROM notes WHERE id = '${identifier//\'/\'\'}' UNION SELECT id FROM notes WHERE title = '${identifier//\'/\'\'}' UNION SELECT note_id FROM aliases WHERE alias = '${identifier//\'/\'\'}' LIMIT 1;"
}

# Processes a single link target and adds it to the database.
#
# Arguments:
#   $1: Raw target string.
#   $2: Source file path.
#   $3: Source note ID.
#
# Outputs:
#   Target note ID if successfully processed.
function _process_link_target() {
    local raw_target="$1"
    local filepath="$2"
    local source_id="$3"
    local current_dir

    current_dir=$(dirname "$filepath")

    if _is_external_uri "$raw_target"; then
        return
    fi

    local target
    local target_path=""
    target=$(${BASENAME} "$raw_target" .md)

    if [[ "$raw_target" == /* ]]; then
        target_path="$raw_target"
    else
        target_path="$current_dir/$raw_target"
    fi

    if [ ! -f "$target_path" ]; then
        local found_file
        found_file=$(_find_file_by_basename "$target")

        if [ -n "$found_file" ] && [ -f "$found_file" ]; then
            target_path="$found_file"
            local new_relative_path
            new_relative_path=$(_calculate_relative_path "$current_dir" "$found_file")
            _update_link_in_file "$filepath" "$raw_target" "$new_relative_path"
        else
            return
        fi
    fi

    local target_id
    target_id=$(_lookup_note_id "$target")

    if [ -z "$target_id" ] && [ -f "$target_path" ]; then
        declare -A target_meta
        _extract_frontmatter "$target_path" target_meta
        target_id="${target_meta[id]}"

        if [ -z "$target_id" ]; then
            target_id=$(_generate_id)
            _insert_id_into_frontmatter "$target_path" "$target_id"
            echo "Generated ID '$target_id' for linked file: $target_path"
        fi
    fi

    if [ -n "$target_id" ]; then
        ${SQLITE3} "$DB_FILE" "INSERT OR IGNORE INTO links (source_id, target_id) VALUES ('$source_id', '$target_id');"
        echo "$target_id"
    fi
}

# Processes all links in a note and updates the links table.
#
# Arguments:
#   $1: The file path.
#   $2: The note ID.
#
# Outputs:
#   Newline-separated list of new target IDs.
function _process_all_links() {
    local filepath="$1"
    local note_id="$2"

    local all_targets
    all_targets=$(_extract_all_link_targets "$filepath")

    IFS=$'\n'
    for raw_target in $all_targets; do
        _process_link_target "$raw_target" "$filepath" "$note_id"
    done
}

# Updates the full-text search index for a note.
#
# Arguments:
#   $1: Note ID.
#   $2: Title.
#   $3: URI.
#   $4: Tags (space-separated).
#   $5: Aliases (newline-separated).
#   $6: Body content.
function _update_fts_index() {
    local id="$1"
    local title="$2"
    local uri="$3"
    local tags="$4"
    local aliases="$5"
    local body="$6"

    local aliases_spaced
    aliases_spaced=$(echo "$aliases" | ${TR} '\n' ' ')
    local full_content="$title $uri $tags $aliases_spaced $body"

    ${SQLITE3} "$DB_FILE" "DELETE FROM notes_fts WHERE note_id = '$id'; INSERT INTO notes_fts (note_id, content) VALUES ('$id', '${full_content//\'/\'\'}');"
}

# Updates backlinks for all affected notes.
#
# Arguments:
#   $1: Old target IDs (newline-separated).
#   $2: New target IDs (newline-separated).
function _update_affected_backlinks() {
    local old_targets="$1"
    local new_targets="$2"

    local affected_targets
    affected_targets=$(printf "%s\n%s\n" "$old_targets" "$new_targets" | ${SORT} -u)

    IFS=$'\n'
    for target_id in $affected_targets; do
        _update_backlinks_for_note "$target_id"
    done
}

# The core indexing function. It parses a note file, extracts metadata,
# and updates the SQLite database.
#
# This function is responsible for:
# - Extracting frontmatter (ID, title, tags, etc.).
# - Generating an ID if one doesn't exist.
# - Updating the 'notes', 'tags', and 'aliases' tables.
# - Parsing all links and updating the 'links' table.
# - Updating the full-text search index.
# - Triggering backlink updates for affected notes.
#
# Arguments:
#   $1: The path to the note file to index.
#   $2 (optional): Set to "false" to skip updating backlinks. Defaults to "true".
function _index_file() {
    local filepath="$1"
    local update_backlinks="${2:-true}"

    declare -A frontmatter
    _extract_frontmatter "$filepath" frontmatter

    local id
    id=$(_ensure_note_has_id "$filepath" frontmatter)

    local type="${frontmatter[type]:-note}"
    echo "Indexing: $filepath (ID: $id, Type: $type)"

    local title="${frontmatter[title]:-}"
    local tags_raw="${frontmatter[tags]:-}"
    local aliases_raw="${frontmatter[aliases]:-}"
    local uri="${frontmatter[uri]:-}"

    local tags
    local aliases
    local body
    local old_targets
    local modified_at
    local relative_path

    tags=$(_normalize_tags "$tags_raw")
    aliases=$(_normalize_aliases "$aliases_raw")
    body=$(_extract_note_body "$filepath")
    old_targets=$(_get_old_link_targets "$id")
    modified_at=$(_get_file_mtime "$filepath")
    relative_path=$(_get_relative_path_from_zettel_dir "$filepath")

    _update_notes_table "$id" "$title" "$type" "$relative_path" "$modified_at"
    _insert_tags "$id" "$tags"
    _insert_aliases "$id" "$aliases"

    local new_targets
    new_targets=$(_process_all_links "$filepath" "$id")

    _update_fts_index "$id" "$title" "$uri" "$tags" "$aliases" "$body"

    if [[ "$update_backlinks" == "true" ]]; then
        _update_affected_backlinks "$old_targets" "$new_targets"
    fi
}
