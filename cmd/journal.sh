#!/usr/bin/env bash

#
# Contains the implementation for the 'journal' command.
#

function _help() {
    echo "journal           Create or open today's daily journal note."
}

function cmd_journal() {
    local journal_dir="$ZETTEL_DIR/$ZK_JOURNAL_DIR"
    ${MKDIR} -p "$journal_dir"
    local today_iso
    today_iso=$(${DATE} +'%Y-%m-%d')
    local note_path="$journal_dir/${today_iso}.md"
    if [ ! -f "$note_path" ]; then
        echo "Creating today's journal entry: $note_path"
        local template_file="$TEMPLATE_DIR/journal_daily.md"
        if [ ! -f "$template_file" ]; then
            ${CAT} >"$template_file" <<'EOM'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "{{TYPE}}"
aliases: ["{{DEFAULT_ALIAS}}"]
tags: [journal, daily]
date: "{{DATE}}"
---
# Journal for {{TITLE}}
## Key Events of the Day
## Thoughts & Reflections
## Today I'm Grateful For
EOM
            echo "Created default journal template at $template_file"
        fi

        declare -A placeholders
        placeholders[ID]=$(_generate_id)
        placeholders[TITLE]=$(${DATE} +"%A, %d %B %Y")
        placeholders[TYPE]="journal"
        placeholders[DEFAULT_ALIAS]="Journal > ${placeholders[TITLE]}"
        placeholders[DATE]="$today_iso"

        _process_template "$template_file" "$note_path" placeholders
    fi
    $EDITOR "$note_path"
    _index_file "$note_path"
}
