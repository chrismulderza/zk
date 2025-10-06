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
