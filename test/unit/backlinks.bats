#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/backlinks.sh"
    
    mock_editor
    
    mock_fzf() {
        head -1
    }
    export -f mock_fzf
    export FZF="mock_fzf"
}

teardown() {
    teardown_test_env
}

@test "cmd_backlinks: finds backlinks for a note" {
    cat > "$ZETTEL_DIR/target.md" <<'EOF'
---
id: "target-id"
title: "Target Note"
---
Target content
EOF
    _index_file "$ZETTEL_DIR/target.md"
    
    cat > "$ZETTEL_DIR/source.md" <<'EOF'
---
id: "source-id"
title: "Source Note"
---
Link to [Target Note](target.md)
EOF
    _index_file "$ZETTEL_DIR/source.md"
    
    run cmd_backlinks
    
    [ "$status" -eq 0 ]
}

@test "cmd_backlinks: handles notes with no backlinks" {
    cat > "$ZETTEL_DIR/lonely.md" <<'EOF'
---
id: "lonely-id"
title: "Lonely Note"
---
No backlinks here
EOF
    _index_file "$ZETTEL_DIR/lonely.md"
    
    run cmd_backlinks
    
    [ "$status" -eq 0 ]
}

@test "cmd_backlinks: handles empty notebook" {
    mock_fzf() {
        return 1
    }
    export -f mock_fzf
    
    run cmd_backlinks
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"No notes found"* ]]
}
