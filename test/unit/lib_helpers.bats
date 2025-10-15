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
