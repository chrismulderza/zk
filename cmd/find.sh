#!/usr/bin/env bash

#
# Contains the implementation for the 'find' command.
#

function _help() {
    echo "find              Interactively search all note contents."
}

function cmd_find() {
    local selection
    selection=$(${RG} --line-number --no-heading --color=always '.' $ZETTEL_DIR/* | ${FZF} --ansi --delimiter ':' --preview "${BAT} --style=full --color=always --theme=base16 --highlight-line {2} {1}" --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
    if [ -n "$selection" ]; then
        local file_path
        file_path=$(echo "$selection" | ${CUT} -d: -f1)
        local line_number
        line_number=$(echo "$selection" | ${CUT} -d: -f2)
        ${EDITOR} "+${line_number}" "$file_path"
    fi
}
