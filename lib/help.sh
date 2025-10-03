#!/usr/bin/env bash
function cmd_help() {
    cat <<EOF
zk - A Zettelkasten and Journaling CLI tool

Usage: zk <command> [options]

Commands:
  init              Initialize the Zettelkasten directory and database.
  add [template]    Create a new note from a template.
  bookmark          Interactively capture a new bookmark.
  journal           Create or open today's daily journal note.
  tags              List all unique tags and their usage count.
  edit              Find any note with fzf and edit it.
  find              Interactively search all note contents.
  query <type> <term> Search the database index.
    Types:
      -t, --tag       Search by tag.
      -a, --alias     Search by alias.
      --type          Search by note type (e.g., bookmark).
      -f, --fulltext  Perform a full-text search.
  index             Rebuild the entire note index from scratch.
  help              Show this help message.
EOF
}