#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/help.sh"
}

teardown() {
    teardown_test_env
}

@test "cmd_help: displays help message" {
    run cmd_help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"zk"* ]]
    [[ "$output" == *"Usage"* ]]
}

@test "cmd_help: lists available commands" {
    run cmd_help
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"init"* ]]
    [[ "$output" == *"add"* ]]
    [[ "$output" == *"journal"* ]]
    [[ "$output" == *"query"* ]]
}

@test "cmd_help: shows command descriptions" {
    run cmd_help
    
    [ "$status" -eq 0 ]
    local line_count
    line_count=$(echo "$output" | wc -l)
    [ "$line_count" -gt 5 ]
}
