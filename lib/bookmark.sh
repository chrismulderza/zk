#!/usr/bin/env bash
function cmd_bookmark() {
    local bookmark_dir="$ZETTEL_DIR/$ZK_BOOKMARK_DIR"; mkdir -p "$bookmark_dir"
    local template_file="$TEMPLATE_DIR/bookmark.md"; echo "Capturing a new bookmark..."
    read -r -p "Title: " title; read -r -p "URL (uri): " uri; read -r -p "Tags (space-separated): " tags_input; read -r -p "Description: " description
    if [ ! -f "$template_file" ]; then
        cat > "$template_file" <<'EOF'
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
EOF
        echo "Created default bookmark template at $template_file"
    fi
    local safe_title; safe_title=$(_sed_escape "$title"); local safe_uri; safe_uri=$(_sed_escape "$uri")
    local safe_description; safe_description=$(_sed_escape "$description")
    local id; id=$(_generate_id); local slug; slug=$(_slugify "$title"); local note_path="$bookmark_dir/${id}-${slug}.md"; local date; date=$(date -I)
    local tags_yaml; tags_yaml=$(echo "$tags_input" | sed 's/ \+/", "/g; s/^/"/; s/$/"/'); local tags_list; tags_list=$(echo "$tags_input" | sed 's/ \+/, /g')
    sed -e "s/{{ID}}/$id/g" -e "s/{{TITLE}}/$safe_title/g" -e "s/{{URI}}/$safe_uri/g" -e "s/{{TAGS_YAML}}/$tags_yaml/g" -e "s/{{TAGS_LIST}}/$tags_list/g" -e "s/{{DATE}}/$date/g" -e "s/{{DESCRIPTION}}/$safe_description/g" "$template_file"