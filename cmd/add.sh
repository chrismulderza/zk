#!/usr/bin/env bash

#
# Contains the implementation for the 'add' command.
#

function _help() {
    echo "add [template]    Create a new note from a template."
}

function cmd_add() {
    local template_arg="${1:-note}"
    local template_file="$TEMPLATE_DIR/${template_arg}.md"

    if [ ! -f "$template_file" ]; then
        if [ "$template_arg" == "note" ]; then
            echo "No 'note' template found in $TEMPLATE_DIR. Creating a default 'note.md'." >&2
            ${CAT} >"$template_file" <<'EOM'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "note"
tags: []
date: "{{DATE}}"
---
# {{TITLE}}
EOM
        else
            echo "Error: Template '$template_arg' not found in $TEMPLATE_DIR" >&2
            exit 1
        fi
    fi

    # Extract template configuration
    declare -A template_config
    _extract_template_config "$template_file" template_config
    
    # Determine output directory
    local output_dir="${template_config[output_dir]:-}"
    local note_dir="$ZETTEL_DIR"
    if [[ -n "$output_dir" ]]; then
        note_dir="$ZETTEL_DIR/$output_dir"
        mkdir -p "$note_dir"
    fi

    declare -A placeholders
    local template_type
    template_type=$(${BASENAME} "$template_file" .md)

    # Always prompt for title first as it may be used to pre-populate other placeholders
    local title
    read -r -p "Enter title: " title
    placeholders[TITLE]="$title"

    # Pre-populate known placeholders
    placeholders[ID]=$(_generate_id)
    placeholders[DATE]=$(${DATE} -I)
    placeholders[TYPE]="${template_type:-note}"

    local all_placeholders
    all_placeholders=$(_get_template_placeholders "$template_file")

    # Generate DEFAULT_ALIAS if needed and not already set
    if [[ -z "${placeholders[DEFAULT_ALIAS]:-}" && "$all_placeholders" =~ "DEFAULT_ALIAS" ]]; then
        local type_pretty
        type_pretty=$(_title_case "${template_type//_/ }")
        local title_cased
        title_cased=$(_title_case "${placeholders[TITLE]:-}")
        placeholders[DEFAULT_ALIAS]="${type_pretty} > ${title_cased}"
    fi

    # Prompt for all remaining placeholders that are empty
    for key in $all_placeholders; do
        if [[ -z "${placeholders[$key]:-}" ]]; then
            local prompt_key=${key//_/ }
            prompt_key=${prompt_key,,}
            read -r -p "Enter ${prompt_key^}: " value
            placeholders[$key]="$value"
        fi
    done

    # Generate filename based on template config
    local filename_format="${template_config[filename_format]:-id-title}"
    local filename
    filename=$(_generate_filename "$filename_format" placeholders)
    local new_note_path="$note_dir/${filename}.md"

    _process_template "$template_file" "$new_note_path" placeholders

    echo "Created new note: $new_note_path"
    $EDITOR "$new_note_path"
    _index_file "$new_note_path"
}
