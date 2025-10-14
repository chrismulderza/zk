#!/usr/bin/env bash

#
# Contains the implementation for the 'bookmark' command.
#

function _help() {
    echo "bookmark          Interactively capture a new bookmark."
}

function cmd_bookmark() {
    local bookmark_dir="$ZETTEL_DIR/$ZK_BOOKMARK_DIR"; ${MKDIR} -p "$bookmark_dir"
    local template_file="$TEMPLATE_DIR/bookmark.md"; echo "Capturing a new bookmark..."

    if [ ! -f "$template_file" ]; then
        ${CAT} > "$template_file" <<'EOM'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "bookmark"
uri: "{{URI}}"
tags: [{{TAGS_YAML}}]
date: "{{DATE}}"
---

# Bookmark: {{TITLE}}

- **URL**: {{URI}}
- **Tags**: {{TAGS_LIST}}

## Description

{{DESCRIPTION}}

EOM
        echo "Created default bookmark template at $template_file"
    fi

    declare -A placeholders
    read -r -p "Title: " title
    read -r -p "URL (uri): " uri
    read -r -p "Tags (space-separated): " tags_input
    read -r -p "Description: " description

    placeholders[ID]=$(_generate_id)
    placeholders[TITLE]="$title"
    placeholders[URI]="$uri"
    placeholders[DESCRIPTION]="$description"
    placeholders[DATE]=$(${DATE} -I)
    placeholders[TAGS_YAML]=$(echo "$tags_input" | ${SED} 's/ \{1,\}/, /g')
    placeholders[TAGS_LIST]=$(echo "$tags_input" | ${SED} 's/ \{1,\}/, /g')

    local slug; slug=$(_slugify "$title")
    local note_path="$bookmark_dir/${placeholders[ID]}-${slug}.md"

    _process_template "$template_file" "$note_path" placeholders
        
    echo "Bookmark captured: $note_path"
    _index_file "$note_path"
}
