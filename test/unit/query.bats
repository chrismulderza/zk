#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/query.sh"
    # Mock fzf to simply output its input, simulating a selection.
    mock_fzf() {
        cat
    }
    export -f mock_fzf
    export FZF="mock_fzf"
    # Mock the editor
    mock_editor
}

teardown() {
    teardown_test_env
}

@test "cmd_query: finds notes by a single tag" {
    # Create and index a note with the target tag
    cat > "$ZETTEL_DIR/note1.md" <<'EOM'
---
id: 202510151000
title: Note One
tags: [bash, scripting]
---
This note is about bash.
EOM
    _index_file "$ZETTEL_DIR/note1.md"

    # Create and index another note without the tag
    cat > "$ZETTEL_DIR/note2.md" <<'EOM'
---
id: 202510151001
title: Note Two
tags: [python]
---
This note is about python.
EOM
    _index_file "$ZETTEL_DIR/note2.md"

    run cmd_query --tag "bash"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"note1.md"* ]]
    [[ "$output" != *"note2.md"* ]]
}

@test "cmd_query: finds notes by an alias" {
    # Create and index a note with the target alias
    cat > "$ZETTEL_DIR/note1.md" <<'EOM'
---
id: 202510151002
title: Note One Alias
aliases: [n1, note-one]
---
This note has an alias.
EOM
    _index_file "$ZETTEL_DIR/note1.md"

    # Create and index another note without the alias
    cat > "$ZETTEL_DIR/note2.md" <<'EOM'
---
id: 202510151003
title: Note Two Alias
aliases: [n2]
---
This note has a different alias.
EOM
    _index_file "$ZETTEL_DIR/note2.md"

    run cmd_query --alias "note-one"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"note1.md"* ]]
    [[ "$output" != *"note2.md"* ]]
}

@test "cmd_query: finds notes by type" {
    # Create and index a note of the target type
    cat > "$ZETTEL_DIR/note1.md" <<'EOM'
---
id: 202510151004
title: Bookmark Note
type: bookmark
---
This is a bookmark.
EOM
    _index_file "$ZETTEL_DIR/note1.md"

    # Create and index another note of a different type
    cat > "$ZETTEL_DIR/note2.md" <<'EOM'
---
id: 202510151005
title: Journal Note
type: journal
---
This is a journal entry.
EOM
    _index_file "$ZETTEL_DIR/note2.md"

    run cmd_query --type "bookmark"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"note1.md"* ]]
    [[ "$output" != *"note2.md"* ]]
}

@test "cmd_query: performs a full-text search" {
    # Create and index a note with specific content
    cat > "$ZETTEL_DIR/note1.md" <<'EOM'
---
id: 202510151006
title: FTS Note One
---
The quick brown fox jumps over the lazy dog.
EOM
    _index_file "$ZETTEL_DIR/note1.md"

    # Create and index another note with different content
    cat > "$ZETTEL_DIR/note2.md" <<'EOM'
---
id: 202510151007
title: FTS Note Two
---
A journey of a thousand miles begins with a single step.
EOM
    _index_file "$ZETTEL_DIR/note2.md"

    run cmd_query --fulltext "fox"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"note1.md"* ]]
    [[ "$output" != *"note2.md"* ]]
}

@test "cmd_query: returns no results when no match is found" {
    # Create and index a note
    cat > "$ZETTEL_DIR/note1.md" <<'EOM'
---
id: 202510151008
title: No Match Note
tags: [testing]
---
Content.
EOM
    _index_file "$ZETTEL_DIR/note1.md"

    run cmd_query --tag "nonexistent"
    
    [ "$status" -eq 0 ]
    [[ "$output" == "No results found."* ]]
}
