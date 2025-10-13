#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    
    # Source the command we are testing
    source "$BATS_TEST_DIRNAME/../../cmd/bookmark.sh"
    
    # Mock dependencies
    mock_editor
    _index_file() {
        echo "Mock index called for $1"
    }
    _generate_id() {
        echo "bookmark-id"
    }
    export -f cmd_bookmark _index_file _generate_id
    export ZETTEL_DIR XDG_CONFIG_HOME ZK_BOOKMARK_DIR TEMPLATE_DIR
}

teardown() {
    teardown_test_env
}

# --- Test Cases ---

@test "cmd_bookmark: creates a new bookmark from user input" {
    # --- Arrange ---
    
    # --- Act ---
    
    # 2. Run the command, using a here-document for input
    cmd_bookmark <<EOF
A Great Website
https://example.com
bash scripting tests
This is a test description.
EOF

    # --- Assertions ---
    
    local bookmark_path="$ZETTEL_DIR/$ZK_BOOKMARK_DIR/bookmark-id-a-great-website.md"

    # DEBUG: Print the content of the generated file
    echo "--- Content of $bookmark_path ---"
    cat "$bookmark_path"
    echo "------------------------------------"

    # 1. Verify the bookmark file was created
    [ -f "$bookmark_path" ]

    # 2. Verify the YAML frontmatter metadata
    grep '^id: "bookmark-id"' "$bookmark_path"
    grep '^title: "A Great Website"' "$bookmark_path"
    grep '^type: "bookmark"' "$bookmark_path"
    grep '^uri: "https://example.com"' "$bookmark_path"
    grep '^tags: \[bash, scripting, tests\]' "$bookmark_path"

    # 3. Verify the description content
    grep 'This is a test description.' "$bookmark_path"

    # 4. Verify the mock editor was not called for bookmarks (should be non-interactive)
    ! grep "Edited by mock" "$bookmark_path"
}
