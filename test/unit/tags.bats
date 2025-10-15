#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/tags.sh"
}

teardown() {
    teardown_test_env
}

@test "cmd_tags: lists all tags with usage count" {
    cat > "$ZETTEL_DIR/note1.md" <<'EOF'
---
id: "test1"
title: "Note 1"
tags: [bash, testing]
---
Content
EOF
    _index_file "$ZETTEL_DIR/note1.md"
    
    cat > "$ZETTEL_DIR/note2.md" <<'EOF'
---
id: "test2"
title: "Note 2"
tags: [bash, scripting]
---
Content
EOF
    _index_file "$ZETTEL_DIR/note2.md"
    
    run cmd_tags
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"bash"* ]]
    [[ "$output" == *"testing"* ]]
    [[ "$output" == *"scripting"* ]]
}

@test "cmd_tags: shows correct usage counts" {
    cat > "$ZETTEL_DIR/note1.md" <<'EOF'
---
id: "test1"
title: "Note 1"
tags: [bash]
---
Content
EOF
    _index_file "$ZETTEL_DIR/note1.md"
    
    cat > "$ZETTEL_DIR/note2.md" <<'EOF'
---
id: "test2"
title: "Note 2"
tags: [bash]
---
Content
EOF
    _index_file "$ZETTEL_DIR/note2.md"
    
    run cmd_tags
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"2"*"bash"* ]]
}

@test "cmd_tags: handles notebook with no tags" {
    run cmd_tags
    
    [ "$status" -eq 0 ]
}
