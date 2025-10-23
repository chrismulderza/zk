#!/usr/bin/env bats

load '../helpers.bash'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "_title_case: converts string to Title Case" {
    run _title_case "hello world"
    
    [ "$status" -eq 0 ]
    [ "$output" = "Hello World" ]
}

@test "_title_case: handles single word" {
    run _title_case "hello"
    
    [ "$status" -eq 0 ]
    [ "$output" = "Hello" ]
}

@test "_title_case: handles already capitalized text" {
    run _title_case "Hello World"
    
    [ "$status" -eq 0 ]
    [ "$output" = "Hello World" ]
}

@test "_sed_escape: escapes special characters" {
    run _sed_escape "test/path&special"
    
    [ "$status" -eq 0 ]
    [ "$output" = "test\/path\&special" ]
}

@test "_sed_escape: handles backslashes" {
    run _sed_escape "test\\path"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"\\"* ]]
}

@test "_is_external_uri: recognizes http URLs" {
    run _is_external_uri "https://example.com"
    [ "$status" -eq 0 ]
    
    run _is_external_uri "http://example.com"
    [ "$status" -eq 0 ]
}

@test "_is_external_uri: recognizes ftp URLs" {
    run _is_external_uri "ftp://server.com"
    [ "$status" -eq 0 ]
    
    run _is_external_uri "ftps://server.com"
    [ "$status" -eq 0 ]
}

@test "_is_external_uri: recognizes mailto URLs" {
    run _is_external_uri "mailto:user@example.com"
    [ "$status" -eq 0 ]
}

@test "_is_external_uri: recognizes file URLs" {
    run _is_external_uri "file:///path/to/file"
    [ "$status" -eq 0 ]
}

@test "_is_external_uri: recognizes absolute paths" {
    run _is_external_uri "/absolute/path"
    [ "$status" -eq 0 ]
}

@test "_is_external_uri: rejects relative paths" {
    run _is_external_uri "relative/path"
    [ "$status" -eq 1 ]
    
    run _is_external_uri "file.md"
    [ "$status" -eq 1 ]
}

@test "_calculate_relative_path: calculates sibling path" {
    run _calculate_relative_path "/path/to/source" "/path/to/target"
    
    [ "$status" -eq 0 ]
    [ "$output" = "../target" ]
}

@test "_calculate_relative_path: calculates parent path" {
    run _calculate_relative_path "/path/to/source" "/path/target"
    
    [ "$status" -eq 0 ]
    [ "$output" = "../../target" ]
}

@test "_calculate_relative_path: calculates nested path" {
    run _calculate_relative_path "/path/to" "/path/to/deep/nested/file"
    
    [ "$status" -eq 0 ]
    [ "$output" = "deep/nested/file" ]
}

@test "_calculate_relative_path: calculates same directory" {
    run _calculate_relative_path "/path/to/dir" "/path/to/dir"
    
    [ "$status" -eq 0 ]
    [ "$output" = "." ]
}

@test "_generate_id: generates 6-character hex ID" {
    run _generate_id
    
    [ "$status" -eq 0 ]
    [ "${#output}" -eq 6 ]
    [[ "$output" =~ ^[a-f0-9]{6}$ ]]
}

@test "_generate_id: generates unique IDs" {
    local id1
    local id2
    id1=$(_generate_id)
    id2=$(_generate_id)
    
    [ "$id1" != "$id2" ]
}

@test "_id_exists_in_db: returns true for existing ID" {
    local note_path="$ZETTEL_DIR/test.md"
    cat > "$note_path" <<'EOF'
---
id: "abc123"
title: "Test"
---
Content
EOF
    _index_file "$note_path"
    
    run _id_exists_in_db "abc123"
    [ "$status" -eq 0 ]
}

@test "_id_exists_in_db: returns false for non-existing ID" {
    run _id_exists_in_db "nonexistent"
    [ "$status" -eq 1 ]
}

@test "_ensure_initialized: exits if not initialized" {
    rm -rf "$ZETTEL_DIR/.zk"
    
    run _ensure_initialized
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"not initialized"* ]]
}

@test "_ensure_initialized: succeeds if initialized" {
    run _ensure_initialized
    
    [ "$status" -eq 0 ]
}

@test "db_init: creates all required tables" {
    rm -f "$DB_FILE"
    touch "$DB_FILE"
    
    db_init
    
    local tables
    tables=$(sqlite3 "$DB_FILE" ".tables")
    [[ "$tables" == *"notes"* ]]
    [[ "$tables" == *"tags"* ]]
    [[ "$tables" == *"aliases"* ]]
    [[ "$tables" == *"links"* ]]
    [[ "$tables" == *"notes_fts"* ]]
}

@test "_remove_quotes: removes double quotes" {
    run _remove_quotes '"quoted"'
    
    [ "$status" -eq 0 ]
    [ "$output" = "quoted" ]
}

@test "_remove_quotes: removes single quotes" {
    run _remove_quotes "'quoted'"
    
    [ "$status" -eq 0 ]
    [ "$output" = "quoted" ]
}

@test "_remove_quotes: removes escaped quotes" {
    run _remove_quotes '\"quoted\"'
    
    [ "$status" -eq 0 ]
    [ "$output" = "quoted" ]
}

@test "_remove_quotes: handles unquoted strings" {
    run _remove_quotes "unquoted"
    
    [ "$status" -eq 0 ]
    [ "$output" = "unquoted" ]
}

@test "_normalize_tags: converts to space-separated" {
    run _normalize_tags "tag1, tag2, tag3"
    
    [ "$status" -eq 0 ]
    [ "$output" = "tag1  tag2  tag3" ]
}

@test "_normalize_aliases: converts to newline-separated" {
    run _normalize_aliases "alias1, alias2, alias3"
    
    [ "$status" -eq 0 ]
    [ "$(echo "$output" | wc -l)" -eq 3 ]
}

@test "_has_frontmatter: detects frontmatter" {
    local test_file="$ZETTEL_DIR/test.md"
    cat > "$test_file" <<'EOF'
---
id: test
---
Content
EOF
    
    run _has_frontmatter "$test_file"
    [ "$status" -eq 0 ]
}

@test "_has_frontmatter: detects missing frontmatter" {
    local test_file="$ZETTEL_DIR/test.md"
    cat > "$test_file" <<'EOF'
# Just content
No frontmatter here
EOF
    
    run _has_frontmatter "$test_file"
    [ "$status" -eq 1 ]
}

@test "_extract_template_config: extracts output_dir and filename_format" {
    local template_file="$BATS_TEST_TMPDIR/template_with_config.md"
    cat > "$template_file" <<'EOF'
---
config:
  output_dir: "meetings"
  filename_format: "date-title-id"
---
id: "{{ID}}"
title: "{{TITLE}}"
---
EOF
    
    declare -A config
    _extract_template_config "$template_file" config
    
    [[ "${config[output_dir]}" == "meetings" ]]
    [[ "${config[filename_format]}" == "date-title-id" ]]
}

@test "_extract_template_config: handles missing config section" {
    local template_file="$BATS_TEST_TMPDIR/template_no_config.md"
    cat > "$template_file" <<'EOF'
---
id: "{{ID}}"
title: "{{TITLE}}"
---
EOF
    
    declare -A config
    _extract_template_config "$template_file" config
    
    [[ -z "${config[output_dir]:-}" ]]
    [[ -z "${config[filename_format]:-}" ]]
}

@test "_extract_template_config: handles config with quoted values" {
    local template_file="$BATS_TEST_TMPDIR/template_quoted.md"
    cat > "$template_file" <<'EOF'
---
config:
  output_dir: "my/nested/path"
  filename_format: "date-title"
---
id: "{{ID}}"
---
EOF
    
    declare -A config
    _extract_template_config "$template_file" config
    
    [[ "${config[output_dir]}" == "my/nested/path" ]]
    [[ "${config[filename_format]}" == "date-title" ]]
}

@test "_generate_filename: date-title-id format" {
    declare -A data
    data[DATE]="2025-10-15"
    data[TITLE]="My Test Note"
    data[ID]="abc123"
    
    local result
    result=$(_generate_filename "date-title-id" data)
    
    [[ "$result" == "2025-10-15-my-test-note-abc123" ]]
}

@test "_generate_filename: id-title format" {
    declare -A data
    data[DATE]="2025-10-15"
    data[TITLE]="My Test Note"
    data[ID]="abc123"
    
    local result
    result=$(_generate_filename "id-title" data)
    
    [[ "$result" == "abc123-my-test-note" ]]
}

@test "_generate_filename: date-title format" {
    declare -A data
    data[DATE]="2025-10-15"
    data[TITLE]="My Test Note"
    data[ID]="abc123"
    
    local result
    result=$(_generate_filename "date-title" data)
    
    [[ "$result" == "2025-10-15-my-test-note" ]]
}

@test "_generate_filename: date format" {
    declare -A data
    data[DATE]="2025-10-15"
    data[TITLE]="My Test Note"
    data[ID]="abc123"
    
    local result
    result=$(_generate_filename "date" data)
    
    [[ "$result" == "2025-10-15" ]]
}

@test "_generate_filename: title format" {
    declare -A data
    data[DATE]="2025-10-15"
    data[TITLE]="My Test Note"
    data[ID]="abc123"
    
    local result
    result=$(_generate_filename "title" data)
    
    [[ "$result" == "my-test-note" ]]
}

@test "_generate_filename: id format" {
    declare -A data
    data[DATE]="2025-10-15"
    data[TITLE]="My Test Note"
    data[ID]="abc123"
    
    local result
    result=$(_generate_filename "id" data)
    
    [[ "$result" == "abc123" ]]
}

@test "_get_template_placeholders: excludes config section" {
    local template_file="$BATS_TEST_TMPDIR/template_with_config.md"
    cat > "$template_file" <<'EOF'
---
config:
  output_dir: "meetings"
  filename_format: "date-title-id"
---
id: "{{ID}}"
title: "{{TITLE}}"
project: "{{PROJECT}}"
---
# {{TITLE}}
EOF
    
    local result
    result=$(_get_template_placeholders "$template_file")
    
    echo "$result" | grep -q "ID"
    echo "$result" | grep -q "TITLE"
    echo "$result" | grep -q "PROJECT"
    
    # Should NOT contain config keys
    ! echo "$result" | grep -q "output_dir"
    ! echo "$result" | grep -q "filename_format"
}
