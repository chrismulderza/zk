#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
    source "$BATS_TEST_DIRNAME/../../cmd/completion.sh"
}

teardown() {
    teardown_test_env
}

@test "cmd_completion: generates bash completion script" {
    run cmd_completion
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"complete -F _zk_completions zk"* ]]
}

@test "cmd_completion: includes function definitions" {
    run cmd_completion
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"_zk_completions"* ]]
    [[ "$output" == *"_zk_find_notebook_root_for_completion"* ]]
}

@test "cmd_completion: lists all commands" {
    run cmd_completion
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"init"* ]]
    [[ "$output" == *"add"* ]]
    [[ "$output" == *"journal"* ]]
    [[ "$output" == *"query"* ]]
    [[ "$output" == *"tags"* ]]
}

@test "cmd_completion: output is valid bash" {
    run bash -n <(cmd_completion)
    
    [ "$status" -eq 0 ]
}
