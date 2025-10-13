#!/usr/bin/env bash

function _help() {
    echo "edit              Find any note with fzf and edit it."
}

function cmd_edit() {
    # Use 'find' to get a list of all notes, then pipe to 'fzf' for selection.
    local file_to_edit
    file_to_edit=$(${FIND} "$ZETTEL_DIR" -name "*.md" -type f | ${FZF} --ansi --preview "${BAT} --style=full --color=always --theme=base16 {}" --preview-window 'up,60%,border-bottom')

    # If a file was selected, open it in the editor and re-index it upon closing.
    if [ -n "$file_to_edit" ]; then
        $EDITOR "$file_to_edit"
        _index_file "$file_to_edit"
    fi
}
