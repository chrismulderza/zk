#!/usr/bin/env bash

function _help() {
    cat <<'EOF'
query <type> <term> Search the database index.
  Types:
    -t, --tag       Search by tag.
    -a, --alias     Search by alias.
    --type          Search by note type (e.g., bookmark).
    -f, --fulltext  Perform a full-text search.
EOF
}

function cmd_query() {
    local query_type="$1"
    shift
    local query="$*"
    local results
    case "$query_type" in
    --tag | -t) results=$(${SQLITE3} "$DB_FILE" "SELECT path FROM notes n JOIN tags t ON n.id = t.note_id WHERE t.tag = '$query' ORDER BY n.modified_at DESC;") ;;
    --alias | -a) results=$(${SQLITE3} "$DB_FILE" "SELECT path FROM notes n JOIN aliases a ON n.id = a.note_id WHERE a.alias = '$query' ORDER BY n.modified_at DESC;") ;;
    --type) results=$(${SQLITE3} "$DB_FILE" "SELECT path FROM notes WHERE type = '$query' ORDER BY modified_at DESC;") ;;
    --fulltext | -f) results=$(${SQLITE3} "$DB_FILE" "SELECT n.path FROM notes_fts fts JOIN notes n ON fts.note_id = n.id WHERE fts.notes_fts MATCH '$query' ORDER BY rank, n.modified_at DESC;") ;;
    *)
        echo "Invalid query type. Use --tag, --alias, --type, or --fulltext." >&2
        exit 1
        ;;
    esac
    if [ -z "$results" ]; then
        echo "No results found."
        return
    fi

    # MODIFIED: Handle relative paths returned from the database.
    # The fzf preview must construct an absolute path.
    local choice
    choice=$(echo "$results" | ${FZF} --ansi --preview "${BAT} --style=full --color=always --theme=base16 $ZETTEL_DIR/{}" --preview-window 'up,60%,border-bottom')

    if [ -n "$choice" ]; then
        # Reconstruct the absolute path before opening or re-indexing the file.
        local full_path="$ZETTEL_DIR/$choice"
        $EDITOR "$full_path"
        _index_file "$full_path"
    fi
}
