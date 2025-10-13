#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/add.sh"
}

teardown() {
    teardown_test_env
}

@test "cmd_add: creates a note from a chosen template with interactive input" {
    # --- Mock Dependencies ---
    _generate_id() { echo "test-id"; }
    _index_file() { echo "Mock index called for $1"; }
    mock_editor

    # Mock fzf to return our chosen template
    mock_fzf() {
        echo "meeting"
    }
    export -f mock_fzf
    export FZF="mock_fzf"

    # --- Setup Test Data ---
    local template_file="$TEMPLATE_DIR/meeting.md"
    cat > "$template_file" <<'EOF'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "{{TYPE}}"
project: "{{PROJECT}}"
attendees: [{{ATTENDEES}}]
date: "{{DATE}}"
---
# Meeting: {{TITLE}}

Project: {{PROJECT}}
Attendees: {{ATTENDEES}}
EOF

    # --- Run Test ---
    # Pipe the inputs for the interactive prompts into the command
    # The order matches the discovery of placeholders in the template (alphabetically after pre-filled ones)
    # Pre-filled: DATE, ID, TYPE
    # Prompted: ATTENDEES, PROJECT, TITLE
    printf "%s\n" "Alice, Bob" "My Test Project" "Project Kick-off" | cmd_add

    # --- Assertions ---
    local note_path="$ZETTEL_DIR/test-id-project-kick-off.md"
    [ -f "$note_path" ]

    # Get today's date for the assertion
    local today_iso
    today_iso=$(date -I)

    # Verify the content has all expected parts
    grep -q 'id: "test-id"' "$note_path"
    grep -q 'title: "Project Kick-off"' "$note_path"
    grep -q 'type: "meeting"' "$note_path"
    grep -q 'project: "My Test Project"' "$note_path"
    grep -q 'attendees: \[Alice, Bob\]' "$note_path"
    grep -q "date: \"$today_iso\"" "$note_path"
    grep -q '# Meeting: Project Kick-off' "$note_path"
    grep -q 'Project: My Test Project' "$note_path"
    grep -q 'Attendees: Alice, Bob' "$note_path"
    grep -q 'Edited by mock' "$note_path"
}
