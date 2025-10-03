#!/usr/bin/env bash
function cmd_edit() {
    local file_to_edit; file_to_edit=$(find "$ZETTEL_DIR" -name "*.md" -type f | fzf --preview "cat {}")
    if [ -n "$file_to_edit" ]; then $EDITOR "$file_to_edit"; _index_file "$file_to_edit"; fi
}