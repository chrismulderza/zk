#!/usr/bin/env bash
function cmd_edit() {
    # Use 'find' to get a list of all notes, then pipe to 'fzf' for selection.
    local file_to_edit
    file_to_edit=$(find "$ZETTEL_DIR" -name "*.md" -type f | fzf --preview "cat {}")
    
    # If a file was selected, open it in the editor and re-index it upon closing.
    if [ -n "$file_to_edit" ]; then 
        $EDITOR "$file_to_edit"
        _index_file "$file_to_edit"
    fi
}