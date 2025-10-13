#!/usr/bin/env bash

function _help() {
    echo "tags              List all unique tags and their usage count."
}

function cmd_tags() {
    echo "Tag Usage Count:"; echo "-----------------"
    local query="SELECT tag, COUNT(note_id) FROM tags GROUP BY tag ORDER BY COUNT(note_id) DESC, tag ASC;"
    ${SQLITE3} "$DB_FILE" "$query" | while IFS='|' read -r tag count; do ${PRINTF} "%-8s %s\n" "$count" "$tag"; done
}