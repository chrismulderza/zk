#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/find.sh"
    
    mock_editor() {
        echo "Mock editor called for: $1"
    }
    export -f mock_editor
    export EDITOR="mock_editor"
    
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
    
    mock_rg() {
        grep -n --color=always "$@"
    }
    export -f mock_rg
    export RG="mock_rg"
}

teardown() {
    teardown_test_env
}

@test "cmd_find: searches note contents" {
    cat > "$ZETTEL_DIR/searchable.md" <<'EOF'
---
id: "search-id"
title: "Searchable"
---
This is searchable content with unique keyword
EOF
    
    run cmd_find
    
    [ "$status" -eq 0 ]
}

@test "cmd_find: handles empty selection" {
    mock_fzf() {
        return 1
    }
    export -f mock_fzf
    
    cat > "$ZETTEL_DIR/note.md" <<'EOF'
---
id: "test"
title: "Test"
---
Content
EOF
    
    run cmd_find
    
    [ "$status" -eq 0 ]
}
