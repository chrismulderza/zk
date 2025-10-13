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

@test "_extract_frontmatter: extracts simple key-value pairs" {
    # Create a test markdown file with frontmatter
    local test_file="$ZETTEL_DIR/test-note.md"
    cat > "$test_file" <<'EOF'
---
id: abc123
title: Test Note
type: note
---

This is the body content.
EOF

    # Extract frontmatter into an associative array
    declare -A metadata
    _extract_frontmatter "$test_file" metadata

    # Assertions
    [ "${metadata[id]}" = "abc123" ]
    [ "${metadata[title]}" = "Test Note" ]
    [ "${metadata[type]}" = "note" ]
}

@test "_extract_frontmatter: handles quoted values" {
    local test_file="$ZETTEL_DIR/test-quoted.md"
    cat > "$test_file" <<'EOF'
---
id: \"def456\"
title: 'Quoted Title'
uri: \"https://example.com\"
---

Body content here.
EOF

    declare -A metadata
    _extract_frontmatter "$test_file" metadata

    [ "${metadata[id]}" = "def456" ]
    [ "${metadata[title]}" = "Quoted Title" ]
    [ "${metadata[uri]}" = "https://example.com" ]
}

@test "_extract_frontmatter: handles array values" {
    local test_file="$ZETTEL_DIR/test-arrays.md"
    cat > "$test_file" <<'EOF'
---
id: ghi789
title: Array Test
tags: [tag1, tag2, tag3]
aliases: [alias1, alias2]
---

Body content.
EOF

    declare -A metadata
    _extract_frontmatter "$test_file" metadata

    [ "${metadata[id]}" = "ghi789" ]
    [ "${metadata[title]}" = "Array Test" ]
    [ "${metadata[tags]}" = "tag1, tag2, tag3" ]
    [ "${metadata[aliases]}" = "alias1, alias2" ]
}

@test "_extract_frontmatter: handles missing optional fields" {
    local test_file="$ZETTEL_DIR/test-minimal.md"
    cat > "$test_file" <<'EOF'
---
id: jkl012
title: Minimal Note
---

Body content.
EOF

    declare -A metadata
    _extract_frontmatter "$test_file" metadata

    [ "${metadata[id]}" = "jkl012" ]
    [ "${metadata[title]}" = "Minimal Note" ]
    [ -z "${metadata[type]}" ]
    [ -z "${metadata[tags]}" ]
    [ -z "${metadata[uri]}" ]
}

@test "_get_template_placeholders: extracts all unique placeholders" {
    local template_file="$TEMPLATE_DIR/test_template.md"
    cat > "$template_file" <<'EOF'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "{{TYPE}}"
---
# {{TITLE}}

This is a test with a {{CUSTOM_FIELD}} and a repeated {{ID}}.
EOF

    run _get_template_placeholders "$template_file"

    [ "$status" -eq 0 ]
    [ "$output" = $'CUSTOM_FIELD\nID\nTITLE\nTYPE' ]
}

@test "_process_template: replaces placeholders from associative array" {
    local template_file="$TEMPLATE_DIR/test_template.md"
    cat > "$template_file" <<'EOF'
---
id: "{{ID}}"
title: "{{TITLE}}"
type: "{{TYPE}}"
---
# {{TITLE}}

Hello, {{USER}}!
EOF

    declare -A placeholders=( [ID]="abc-123" [TITLE]="My Test Note" [TYPE]="test" [USER]="World" )
    local output_file="$ZETTEL_DIR/output.md"

    run _process_template "$template_file" "$output_file" placeholders

    [ "$status" -eq 0 ]
    [ -f "$output_file" ]
    
    grep -q 'id: "abc-123"' "$output_file"
    grep -q 'title: "My Test Note"' "$output_file"
    grep -q 'type: "test"' "$output_file"
    grep -q '# My Test Note' "$output_file"
    grep -q 'Hello, World!' "$output_file"
}