#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    
    # The _index_file function requires a database
    db_init
}

teardown() {
    teardown_test_env
}

@test "_index_file: correctly indexes a note with tags and aliases" {
    # --- Setup ---
    
    # 1. Create a dummy note file to be indexed
    local note_path="$ZETTEL_DIR/test-id-a-test-note.md"
    cat > "$note_path" <<EOF
---
id: "test-id"
title: "A Test Note"
type: "note"
aliases: ["Test Alias 1", "Test Alias 2"]
tags: [bash, testing, zk]
date: "2025-10-06"
---

# A Test Note

This is the body of the test note.
EOF

    # --- Run Test ---
    
    # Run the index function on the new file
    run _index_file "$note_path"

    # --- Assertions ---
    
    [ "$status" -eq 0 ]

    # 1. Verify the main note entry in the 'notes' table
    local note_entry
    note_entry=$(sqlite3 "$DB_FILE" "SELECT title, type FROM notes WHERE id = 'test-id'")
    [ "$note_entry" = "A Test Note|note" ]

    # 2. Verify the tags in the 'tags' table
    local tags
    tags=$(sqlite3 "$DB_FILE" "SELECT tag FROM tags WHERE note_id = 'test-id' ORDER BY tag")
    [ "$tags" = $'bash\ntesting\nzk' ]

    # 3. Verify the aliases in the 'aliases' table
    local aliases
    aliases=$(sqlite3 "$DB_FILE" "SELECT alias FROM aliases WHERE note_id = 'test-id' ORDER BY alias")
    [ "$aliases" = $'Test Alias 1\nTest Alias 2' ]
}

@test "_index_file: auto-generates missing ID and indexes file" {
    local note_path="$ZETTEL_DIR/note-without-id.md"
    cat > "$note_path" <<EOF
---
title: "Note Without ID"
type: "note"
---
# Note Without ID
This note has no ID field.
EOF
    
    run _index_file "$note_path"
    
    [ "$status" -eq 0 ]
    
    declare -A metadata
    _extract_frontmatter "$note_path" metadata
    [ -n "${metadata[id]}" ]
    
    local note_count
    note_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM notes WHERE id = '${metadata[id]}'")
    [ "$note_count" -eq 1 ]
}

@test "_index_file: resolves links to files in subdirectories" {
    mkdir -p "$ZETTEL_DIR/journal"
    local target_path="$ZETTEL_DIR/journal/daily-note.md"
    cat > "$target_path" <<EOF
---
id: "target-id"
title: "Daily Note"
type: "journal"
---
# Daily Note
EOF
    
    local source_path="$ZETTEL_DIR/source-note.md"
    cat > "$source_path" <<EOF
---
id: "source-id"
title: "Source Note"
---
# Source Note
Link to [Daily Note](journal/daily-note.md)
EOF
    
    _index_file "$target_path"
    _index_file "$source_path"
    
    local link_count
    link_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM links WHERE source_id = 'source-id' AND target_id = 'target-id'")
    [ "$link_count" -eq 1 ]
}

@test "_index_file: finds and links files by basename search" {
    local target_path="$ZETTEL_DIR/abc123-my-note.md"
    cat > "$target_path" <<EOF
---
id: "abc123"
title: "My Note"
---
# My Note
EOF
    
    local source_path="$ZETTEL_DIR/def456-another-note.md"
    cat > "$source_path" <<EOF
---
id: "def456"
title: "Another Note"
---
# Another Note
Link to [My Note](my-note.md)
EOF
    
    _index_file "$target_path"
    _index_file "$source_path"
    
    local link_count
    link_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM links WHERE source_id = 'def456' AND target_id = 'abc123'")
    [ "$link_count" -eq 1 ]
}

@test "_index_file: generates ID for linked file without ID" {
    local target_path="$ZETTEL_DIR/target-no-id.md"
    cat > "$target_path" <<EOF
---
title: "Target Without ID"
---
# Target Without ID
EOF
    
    local source_path="$ZETTEL_DIR/source-with-id.md"
    cat > "$source_path" <<EOF
---
id: "source123"
title: "Source Note"
---
# Source Note
Link to [Target](target-no-id.md)
EOF
    
    _index_file "$source_path"
    
    declare -A target_metadata
    _extract_frontmatter "$target_path" target_metadata
    [ -n "${target_metadata[id]}" ]
    
    local link_count
    link_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM links WHERE source_id = 'source123' AND target_id = '${target_metadata[id]}'")
    [ "$link_count" -eq 1 ]
}

@test "_index_file: skips validation for external URIs" {
    local note_path="$ZETTEL_DIR/note-with-external-links.md"
    cat > "$note_path" <<EOF
---
id: "external-test"
title: "External Links"
---
[GitHub](https://github.com)
[FTP](ftp://server.com/file)
[Local](journal/note.md)
EOF
    
    run _index_file "$note_path"
    [ "$status" -eq 0 ]
    
    grep -q "https://github.com" "$note_path"
    grep -q "ftp://server.com/file" "$note_path"
}

@test "_index_file: fixes broken relative link when file moved" {
    mkdir -p "$ZETTEL_DIR/journal"
    local target_path="$ZETTEL_DIR/journal/moved-note.md"
    cat > "$target_path" <<EOF
---
id: "moved-id"
title: "Moved Note"
---
# Moved Note
EOF
    
    local source_path="$ZETTEL_DIR/source-note.md"
    cat > "$source_path" <<EOF
---
id: "source-id"
title: "Source Note"
---
[Moved Note](moved-note.md)
EOF
    
    _index_file "$target_path"
    _index_file "$source_path"
    
    grep -q "journal/moved-note.md" "$source_path"
    
    local link_count
    link_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM links WHERE source_id = 'source-id' AND target_id = 'moved-id'")
    [ "$link_count" -eq 1 ]
}

@test "_index_file: fixes link when file moved to nested directory" {
    mkdir -p "$ZETTEL_DIR/project/notes"
    local target_path="$ZETTEL_DIR/project/notes/deep-note.md"
    cat > "$target_path" <<EOF
---
id: "deep-id"
title: "Deep Note"
---
# Deep Note
EOF
    
    mkdir -p "$ZETTEL_DIR/journal"
    local source_path="$ZETTEL_DIR/journal/daily.md"
    cat > "$source_path" <<EOF
---
id: "daily-id"
title: "Daily"
---
[Deep Note](../deep-note.md)
EOF
    
    _index_file "$target_path"
    _index_file "$source_path"
    
    grep -q "../project/notes/deep-note.md" "$source_path"
    
    local link_count
    link_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM links WHERE source_id = 'daily-id' AND target_id = 'deep-id'")
    [ "$link_count" -eq 1 ]
}

@test "_index_file: preserves valid relative links" {
    mkdir -p "$ZETTEL_DIR/journal"
    local target_path="$ZETTEL_DIR/journal/valid-note.md"
    cat > "$target_path" <<EOF
---
id: "valid-id"
title: "Valid Note"
---
# Valid Note
EOF
    
    local source_path="$ZETTEL_DIR/source-note.md"
    cat > "$source_path" <<EOF
---
id: "source-id"
title: "Source"
---
[Valid Note](journal/valid-note.md)
EOF
    
    local original_content
    original_content=$(cat "$source_path")
    
    _index_file "$target_path"
    _index_file "$source_path"
    
    local new_content
    new_content=$(cat "$source_path")
    [ "$original_content" = "$new_content" ]
}
