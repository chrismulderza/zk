#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    ZK_TEST_HOME=$(mktemp -d)
    export ZETTEL_DIR="$ZK_TEST_HOME/zettelkasten"
    export XDG_CONFIG_HOME="$ZK_TEST_HOME/config"
    
    source "$BATS_TEST_DIRNAME/../../lib/libzk.sh"
    source "$BATS_TEST_DIRNAME/../../cmd/init.sh"
}

teardown() {
    rm -rf "$ZK_TEST_HOME"
}

@test "cmd_init: creates a new notebook in current directory" {
    cd "$ZK_TEST_HOME"
    mkdir -p test_notebook
    cd test_notebook
    
    run cmd_init
    
    [ "$status" -eq 0 ]
    [ -d ".zk" ]
    [ -f ".zk/zettel.db" ]
    [ -d "journal" ]
    [ -d "resources/bookmarks" ]
    [ -d ".zk/templates" ]
    [ -f ".zk/config.sh" ]
}

@test "cmd_init: creates a new notebook in specified directory" {
    cd "$ZK_TEST_HOME"
    
    run cmd_init "my_notebook"
    
    [ "$status" -eq 0 ]
    [ -d "my_notebook/.zk" ]
    [ -f "my_notebook/.zk/zettel.db" ]
    [ -d "my_notebook/journal" ]
    [ -d "my_notebook/resources/bookmarks" ]
}

@test "cmd_init: reports when notebook already initialized" {
    cd "$ZK_TEST_HOME"
    mkdir -p test_notebook
    cd test_notebook
    
    cmd_init > /dev/null 2>&1
    run cmd_init
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"already initialized"* ]]
}

@test "cmd_init: initializes database with correct schema" {
    cd "$ZK_TEST_HOME"
    mkdir -p test_notebook
    cd test_notebook
    
    cmd_init > /dev/null 2>&1
    
    local tables
    tables=$(sqlite3 .zk/zettel.db ".tables")
    
    [[ "$tables" == *"notes"* ]]
    [[ "$tables" == *"tags"* ]]
    [[ "$tables" == *"aliases"* ]]
    [[ "$tables" == *"links"* ]]
    [[ "$tables" == *"notes_fts"* ]]
}
