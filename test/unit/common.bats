#!/usr/bin/env bats

# Load the test helper script
load '../helpers.bash'

#
# setup() is run before each test case.
#
setup() {
    # Initialize the sandboxed environment
    setup_test_env
}

#
# teardown() is run after each test case.
#
teardown() {
    # Clean up the sandbox
    teardown_test_env
}

@test "_slugify: converts spaces and mixed case" {
    # Run the function with test input
    run _slugify "This is a Test Title"

    # Assertions
    [ "$status" -eq 0 ] # Check for successful exit code
    [ "$output" = "this-is-a-test-title" ]
}

@test "_slugify: removes special characters" {
    run _slugify "A title with!@#$%^&*() characters"
    
    [ "$status" -eq 0 ]
    [ "$output" = "a-title-with-characters" ]
}

@test "_slugify: handles leading/trailing dashes" {
    run _slugify "--a-weirdly-formatted-title--"

    [ "$status" -eq 0 ]
    [ "$output" = "a-weirdly-formatted-title" ]
}
