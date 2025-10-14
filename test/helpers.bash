#!/usr/bin/env bash

# test/helpers.bash

# Creates a temporary, sandboxed environment for zk tests
setup_test_env() {
    # Create a temporary directory for each test run
    ZK_TEST_HOME=$(mktemp -d)

    # Set the environment variables zk uses to point to our sandbox
    export ZETTEL_DIR="$ZK_TEST_HOME/zettelkasten"
    export XDG_CONFIG_HOME="$ZK_TEST_HOME/config"

    # Create the necessary base directories
    mkdir -p "$ZETTEL_DIR/.zk"
    mkdir -p "$XDG_CONFIG_HOME/zk/templates"

    # Source the script we want to test so its functions are available
    source "$BATS_TEST_DIRNAME/../../lib/libzk.sh"
}

# Cleans up the temporary environment after a test
teardown_test_env() {
    rm -rf "$ZK_TEST_HOME"
}

# Mock the editor to prevent it from opening an interactive session
# It will instead append "Edited by mock" to the file.
mock_editor() {
    export EDITOR="mock_editor_func"
    mock_editor_func() {
        echo "Edited by mock" >> "$1"
    }
    export -f mock_editor_func
}
