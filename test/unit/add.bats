#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    
    # For this test file, we need the add command
    source "$BATS_TEST_DIRNAME/../../lib/add.sh"
}

teardown() {
    teardown_test_env
}

@test "cmd_add: creates a new note from input" {
    # --- Mock Dependencies ---
    
    # 1. Mock the _generate_id function to return a predictable ID
    _generate_id() {
        echo "test-id"
    }
    
    # 2. Mock the _index_file function to do nothing, isolating this test
    _index_file() {
        # In a real test, you might have this write to a log file
        echo "Mock index called for $1"
    }
    
    # 3. Mock the EDITOR so it doesn't block the test
    mock_editor

    # --- Run Test ---
    
    # Pipe the title into the function to simulate user input for `read`
    echo "My Test Note" | cmd_add
    
    # --- Assertions ---
    
    local note_path="$ZETTEL_DIR/test-id-my-test-note.md"

    # 1. Check if the note file was created
    [ -f "$note_path" ]

    # 2. Check if the title was correctly written to the file
    grep 'title:.*My Test Note' "$note_path"

    # 3. Check if the mock editor was called
    grep "Edited by mock" "$note_path"
}
