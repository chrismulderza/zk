#!/usr/bin/env bash
function cmd_add() {
    local type="${1:-note}"; local template_file="$TEMPLATE_DIR/${type}.md"
    if [ ! -f "$template_file" ]; then
        if [[ "$type" == "note" ]]; then
            cat > "$template_file" <<'EOF'
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
            echo "Created default note template at $template_file"
        else echo "Error: Template '$type' not found in $TEMPLATE_DIR" >&2; exit 1; fi
    fi
    local id; id=$(_generate_id); read -r -p "Enter note title: " title
    local safe_title; safe_title=$(_sed_escape "$title")
    local type_pretty; type_pretty=$(_title_case "${type//_/ }"); local title_cased; title_cased=$(_title_case "$title")
    local default_alias="${type_pretty} > ${title_cased}"; local safe_default_alias; safe_default_alias=$(_sed_escape "$default_alias")
    local slug; slug=$(_slugify "$title"); local new_note_path="$ZETTEL_DIR/${id}-${slug}.md"; local date; date=$(date -I)
    sed -e "s/{{ID}}/$id/g" -e "s/{{TITLE}}/$safe_title/g" -e "s/{{TYPE}}/$type/g" -e "s/{{DEFAULT_ALIAS}}/$safe_default_alias/g" -e "s/{{DATE}}/$date/g" "$template_file" > "$new_note_path"
    echo "Created new note: $new_note_path"; $EDITOR "$new_note_path"; _index_file "$new_note_path"
}