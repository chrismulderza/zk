#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    
    # Source the command we are testing
    source "$BATS_TEST_DIRNAME/../../cmd/journal.sh"
    
    # Mock dependencies
    mock_editor
    _index_file() {
        echo "Mock index called for $1"
    }
}

teardown() {
    teardown_test_env
    # Unset the mock date function
    unset -f date
}

# --- Test Cases ---

@test "cmd_journal: creates a new journal note if one doesn't exist" {
    # --- Arrange ---
    
    # 1. Mock the date command to return a predictable date
    date() {
        if [[ "$1" == +'%Y-%m-%d' ]]; then
            echo "2025-10-06"
        elif [[ "$1" == +"%A, %d %B %Y" ]]; then
            echo "Monday, 06 October 2025"
        else
            command date "$@"
        fi
    }
    export -f date
    
    # 2. Create a default journal template
    local template_path="$XDG_CONFIG_HOME/zk/templates/journal_daily.md"
    cat > "$template_path" <<EOF
---
id: "{{ID}}"
title: "Journal for {{DATE}}"
type: "journal_daily"
tags: [journal]
date: "{{DATE}}"
---

# Journal - {{DATE}}
EOF

    # --- Act ---
    run cmd_journal
    
    # --- Assertions ---
    [ "$status" -eq 0 ]

    local journal_path="$ZETTEL_DIR/$ZK_JOURNAL_DIR/2025-10-06.md"

    # 1. Verify the journal file was created
    [ -f "$journal_path" ]

    # 2. Verify the content was written from the template
    grep 'title:.*Journal for 2025-10-06' "$journal_path"

    # 3. Verify the mock editor was called on the file
    grep "Edited by mock" "$journal_path"
}

@test "cmd_journal: opens an existing journal note without overwriting it" {
    # --- Arrange ---
    
    # 1. Mock the date command
    date() {
        if [[ "$1" == +'%Y-%m-%d' ]]; then
            echo "2025-10-06"
        elif [[ "$1" == +"%A, %d %B %Y" ]]; then
            echo "Monday, 06 October 2025"
        else
            command date "$@"
        fi
    }
    export -f date

    # 2. Pre-create a journal file
    local journal_dir="$ZETTEL_DIR/$ZK_JOURNAL_DIR"
    mkdir -p "$journal_dir"
    local journal_path="$journal_dir/2025-10-06.md"
    echo "This is an existing entry." > "$journal_path"

    # --- Act ---
    run cmd_journal

    # --- Assertions ---
    [ "$status" -eq 0 ]

    # 1. Verify the original content is still there (file was not overwritten)
    grep "This is an existing entry." "$journal_path"

    # 2. Verify the mock editor was called
    grep "Edited by mock" "$journal_path"
}
