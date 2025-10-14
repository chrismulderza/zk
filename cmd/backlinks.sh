#!/usr/bin/env bash

#
# Contains the implementation for the 'backlinks' command.
#

function _help() {
    echo "backlinks         Interactively find all backlinks for a given note."
}

function cmd_backlinks() {
    # Let user select a note to find backlinks for
    local notes_list
    notes_list=$(${SQLITE3} "$DB_FILE" "SELECT printf('%-17s > %s', type, title) FROM notes ORDER BY modified_at DESC;")
    if [ -z "$notes_list" ]; then echo "No notes found to select."; return; fi

    local selection
    selection=$(echo "$notes_list" | ${FZF} --prompt="Find backlinks for: ")
    if [ -z "$selection" ]; then return; fi

    local selected_title
    selected_title=$(echo "$selection" | ${SED} 's/^.* > //')

    # Find the ID of the selected note
    local target_id
    target_id=$(${SQLITE3} "$DB_FILE" "SELECT id FROM notes WHERE title = '${selected_title//\'/\'\'}' LIMIT 1;")
    if [ -z "$target_id" ]; then echo "Could not find note with title '$selected_title'."; return; fi

    echo "Backlinks for: '$selected_title'"
    echo "-----------------------------------"

    # Find all notes that link to the target_id
    local backlinks
    backlinks=$(${SQLITE3} -separator ' | ' "$DB_FILE" "SELECT n.path, n.title FROM links l JOIN notes n ON l.source_id = n.id WHERE l.target_id = '$target_id' ORDER BY n.modified_at DESC;")

    if [ -z "$backlinks" ]; then
        echo "No backlinks found."
        return
    fi

    # Let user interactively select a backlink to open it
    local backlink_choice
    backlink_choice=$(echo "$backlinks" | ${FZF} --prompt="Open backlink: " | ${CUT} -d'|' -f1 | ${XARGS})
    
    if [ -n "$backlink_choice" ]; then
        local full_path="$ZETTEL_DIR/$backlink_choice"
        $EDITOR "$full_path"
        _index_file "$full_path"
    fi
}
