#!/usr/bin/env bash

function _help() {
    echo "add [template]    Create a new note from a template."
}

function cmd_add() {
    local template_arg="$1"
    local template_file

    if [ -n "$template_arg" ]; then
        template_file="$TEMPLATE_DIR/${template_arg}.md"
        if [ ! -f "$template_file" ]; then
            echo "Error: Template '$template_arg' not found in $TEMPLATE_DIR" >&2
            exit 1
        fi
    else
        local templates
        templates=$(${FIND} "$TEMPLATE_DIR" -maxdepth 1 -name "*.md" -print0 | ${XARGS} -0 -n 1 ${BASENAME} .md)
        if [ -z "$templates" ]; then
            echo "No templates found in $TEMPLATE_DIR. Creating a default 'note.md'." >&2
            local default_template_file="$TEMPLATE_DIR/note.md"
            ${CAT} > "$default_template_file" <<'EOF'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "{{TYPE}}"
aliases: ["{{DEFAULT_ALIAS}}"]
tags: []
date: "{{DATE}}"
---
# {{TITLE}}
EOF
            template_file="$default_template_file"
        else
            local chosen_template
            chosen_template=$(echo "$templates" | ${FZF} --prompt="Choose a template: ")
            if [ -z "$chosen_template" ]; then
                echo "No template selected. Aborting." >&2
                exit 1
            fi
            template_file="$TEMPLATE_DIR/${chosen_template}.md"
        fi
    fi

    declare -A placeholders
    local template_type
    template_type=$(${BASENAME} "$template_file" .md)

    placeholders[ID]=$(_generate_id)
    placeholders[DATE]=$(${DATE} -I)
    placeholders[TYPE]="$template_type"

    local title=""
    local all_placeholders
    all_placeholders=$(_get_template_placeholders "$template_file")

    for key in $all_placeholders; do
        if [ -z "${placeholders[$key]:-}" ]; then
            local prompt_key=${key//_/ }
            prompt_key=${prompt_key,,}
            read -r -p "Enter ${prompt_key^}: " value
            placeholders[$key]="$value"
            if [ "$key" == "TITLE" ]; then
                title="$value"
            fi
        fi
    done

    if [ -z "$title" ]; then
        read -r -p "Enter note title: " title
        placeholders[TITLE]="$title"
    fi

    if [[ -z "${placeholders[DEFAULT_ALIAS]:-}" && "$all_placeholders" =~ "DEFAULT_ALIAS" ]]; then
        local type_pretty; type_pretty=$(_title_case "${template_type//_/ }")
        local title_cased; title_cased=$(_title_case "$title")
        placeholders[DEFAULT_ALIAS]="${type_pretty} > ${title_cased}"
    fi

    local slug; slug=$(_slugify "$title")
    local new_note_path="$ZETTEL_DIR/${placeholders[ID]}-${slug}.md"

    _process_template "$template_file" "$new_note_path" placeholders

    echo "Created new note: $new_note_path"
    (cd "$ZETTEL_DIR" && $EDITOR "$new_note_path")
    _index_file "$new_note_path"
}