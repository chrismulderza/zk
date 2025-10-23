#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/add.sh"
}

teardown() {
    teardown_test_env
}

@test "cmd_add: creates a note from default note template" {
    # --- Mock Dependencies ---
    _generate_id() { echo "test-id"; }
    _index_file() { echo "Mock index called for $1"; }
    mock_editor

    # --- Run Test ---
    # Default behavior: no template specified, defaults to "note"
    printf "%s\n" "My Test Note" | cmd_add
    
    local note_path="$ZETTEL_DIR/test-id-my-test-note.md"
    [ -f "$note_path" ]

    # Get today's date for the assertion
    local today_iso
    today_iso=$(date -I)

    # Verify the content has all expected parts
    grep -q 'id: "test-id"' "$note_path"
    grep -q 'title: "My Test Note"' "$note_path"
    grep -q 'type: "note"' "$note_path"
    grep -q "date: \"$today_iso\"" "$note_path"
    grep -q '# My Test Note' "$note_path"
    grep -q 'Edited by mock' "$note_path"
}

@test "cmd_add: creates a note from a specified template with interactive input" {
    # --- Mock Dependencies ---
    _generate_id() { echo "test-id"; }
    _index_file() { echo "Mock index called for $1"; }
    mock_editor

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
    # Explicitly specify the "meeting" template
    # Prompting order: TITLE (always first), then remaining placeholders alphabetically
    # Pre-filled: DATE, ID, TYPE
    # Prompted: TITLE (first), ATTENDEES, PROJECT
    printf "%s\n" "Project Kick-off" "Alice, Bob" "My Test Project" | cmd_add meeting

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

@test "cmd_add: creates a note in configured subdirectory with custom filename format" {
    _generate_id() { echo "test-id"; }
    _index_file() { echo "Mock index called for $1"; }
    
    cat > "$BATS_TEST_TMPDIR/mock_editor" <<'EDITORSCRIPT'
#!/usr/bin/env bash
echo "Edited by mock" >> "$1"
EDITORSCRIPT
    chmod +x "$BATS_TEST_TMPDIR/mock_editor"
    export EDITOR="$BATS_TEST_TMPDIR/mock_editor"
    
    # Create template with config
    local template_file="$TEMPLATE_DIR/project.md"
    cat > "$template_file" <<'EOF'
---
config:
  output_dir: "projects"
  filename_format: "date-title-id"
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "project"
date: "{{DATE}}"
---
# Project: {{TITLE}}
EOF
    
    printf "%s\n" "New Project" | cmd_add project
    
    local today_iso
    today_iso=$(date -I)
    local note_path="$ZETTEL_DIR/projects/${today_iso}-new-project-test-id.md"
    
    [ -f "$note_path" ]
    grep -q 'id: "test-id"' "$note_path"
    grep -q 'title: "New Project"' "$note_path"
    grep -q 'type: "project"' "$note_path"
    grep -q '# Project: New Project' "$note_path"
    
    # Verify config section is NOT in the output file
    ! grep -q 'config:' "$note_path"
    ! grep -q 'output_dir:' "$note_path"
    ! grep -q 'filename_format:' "$note_path"
}
