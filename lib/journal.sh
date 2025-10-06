#!/usr/bin/env bash
function cmd_journal() {
    local journal_dir="$ZETTEL_DIR/$ZK_JOURNAL_DIR"
    mkdir -p "$journal_dir"
    local today_iso
    today_iso=$(date +'%Y-%m-%d')
    local note_path="$journal_dir/${today_iso}.md"
    if [ ! -f "$note_path" ]; then
        echo "Creating today's journal entry: $note_path"
        local template_file="$TEMPLATE_DIR/journal_daily.md"
        if [ ! -f "$template_file" ]; then
            cat >"$template_file" <<'EOF'
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
EOF
            echo "Created default journal template at $template_file"
        fi
        local id
        id=$(_generate_id)
        local title
        title=$(date +"%A, %d %B %Y")
        local default_alias="Journal > ${title}"
        local safe_title
        safe_title=$(_sed_escape "$title")
        local safe_default_alias
        safe_default_alias=$(_sed_escape "$default_alias")
        sed -e "s/{{ID}}/$id/g" -e "s/{{TITLE}}/$safe_title/g" -e "s/{{TYPE}}/journal/g" -e "s/{{DEFAULT_ALIAS}}/$safe_default_alias/g" -e "s/{{DATE}}/$today_iso/g" "$template_file" >"$note_path"
    fi
    $EDITOR "$note_path"
    _index_file "$note_path"
}
