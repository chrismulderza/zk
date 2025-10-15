#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/edit.sh"
    
    mock_editor
    
    mock_fzf() {
        head -1
    }
    export -f mock_fzf
    export FZF="mock_fzf"
    
    mock_bat() {
        cat "$1"
    }
    export -f mock_bat
    export BAT="mock_bat"
}

teardown() {
    teardown_test_env
}

@test "cmd_edit: opens and re-indexes a selected note" {
    cat > "$ZETTEL_DIR/test-note.md" <<'EOF'
---
id: "test-id"
title: "Test Note"
---
Original content
EOF
    _index_file "$ZETTEL_DIR/test-note.md"
    
    run cmd_edit
    
    [ "$status" -eq 0 ]
    grep -q "Edited by mock" "$ZETTEL_DIR/test-note.md"
}

@test "cmd_edit: handles cancellation" {
    mock_fzf() {
        return 1
    }
    export -f mock_fzf
    
    run cmd_edit
    
    [ "$status" -eq 0 ]
}

@test "cmd_edit: works with nested directories" {
    mkdir -p "$ZETTEL_DIR/journal"
    cat > "$ZETTEL_DIR/journal/daily.md" <<'EOF'
---
id: "daily-id"
title: "Daily"
---
Content
EOF
    _index_file "$ZETTEL_DIR/journal/daily.md"
    
    run cmd_edit
    
    [ "$status" -eq 0 ]
}
