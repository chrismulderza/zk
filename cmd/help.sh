#!/usr/bin/env bash

#
# Contains the implementation for the 'help' command.
#

function _help() {
    echo "help              Show this help message."
}

function cmd_help() {
    cat <<'EOM'
zk - A Zettelkasten and Journaling CLI tool

Usage: zk <command> [options]

Commands:
EOM

    local cmd_dir
    cmd_dir=$(dirname "${BASH_SOURCE[0]}")
    
    local cmd_files
    cmd_files=$(${FIND} "$cmd_dir" -name "*.sh" -type f | ${SORT})
    
    while IFS= read -r cmd_file; do
        source "$cmd_file"
        if declare -f _help >/dev/null 2>&1; then
            echo "  $(_help)"
        fi
    done <<< "$cmd_files"
}
