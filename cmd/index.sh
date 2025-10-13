#!/usr/bin/env bash

function _help() {
    echo "index             Rebuild the entire note index from scratch."
}

function cmd_index() {
    echo "Rebuilding index..."; ${SQLITE3} "$DB_FILE" "DELETE FROM notes; DELETE FROM tags; DELETE FROM aliases; DELETE FROM notes_fts;"
    ${FIND} "$ZETTEL_DIR" -name "*.md" -type f -print0 | while IFS= read -r -d $'\0' file; do _index_file "$file"; done
    echo "Index rebuild complete."
}