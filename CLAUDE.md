# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`zk` is a minimalist, command-line Zettelkasten (personal knowledge management system) built entirely in Bash. It leverages standard Unix tools (sqlite3, fzf, ripgrep, tmux) to provide a fast, local-first, text-based knowledge base where all notes are stored as Markdown files.

## Core Architecture

### Main Entry Point
- **`zk`**: Main executable script that acts as a command router. It sources the user's config file (`~/.config/zk/config.sh`), loads `lib/common.sh` for shared functionality, then routes commands to specific library files in `lib/`.

### Library Structure
All command implementations are in `lib/` and sourced on-demand:
- **`lib/common.sh`**: Core library containing:
  - Configuration defaults (ZETTEL_DIR, DB_FILE, template paths)
  - Database initialization (`db_init`)
  - The critical `_index_file()` function that parses YAML frontmatter, indexes content into SQLite, extracts wikilinks, and maintains backlinks
  - Helper functions (`_generate_id`, `_slugify`, `_title_case`, `_ensure_initialized`)
  - `_update_backlinks_for_note()` function that maintains automatic backlink sections in notes

- **Command files** in `lib/`: Each contains a single `cmd_<name>()` function (e.g., `cmd_add` in `add.sh`, `cmd_find` in `find.sh`)

### Data Storage

#### SQLite Database Schema (zettel.db)
- `notes`: Core table with id, title, type, path, modified_at
- `tags`: Many-to-many relationship for note tags
- `aliases`: Many-to-many relationship for note aliases
- `notes_fts`: FTS5 virtual table for full-text search using Porter stemming
- `links`: Bi-directional link tracking between notes

#### File Structure
- Notes are stored in `$ZETTEL_DIR` (default: `~/.zettelkasten/`)
- Journal notes: `journal/daily/YYYY-MM-DD.md`
- Bookmarks: `resources/bookmarks/<id>-<slug>.md`
- Regular notes: `<id>-<slug>.md` at the root
- Templates: `~/.config/zk/templates/`

### Note Format
All notes use YAML frontmatter with these fields:
```yaml
---
id: <unique-id>
title: <title>
type: <note|journal|bookmark|etc>
tags: [tag1, tag2]
aliases: [alias1, alias2]
uri: <url-for-bookmarks>
---
```

### Indexing System
The `_index_file()` function (lib/common.sh:99-158) is the heart of the system:
1. Extracts YAML frontmatter metadata
2. Extracts body content (excluding backlink section)
3. Updates notes, tags, aliases, and links tables
4. Performs full-text indexing into notes_fts
5. Extracts wikilinks `[[target]]` and markdown links `[text](target)`
6. Resolves link targets by matching against note IDs, titles, or aliases
7. Automatically updates backlink sections in both source and target notes

### Backlink System
- Backlinks are auto-generated and maintained between `<!-- BACKLINK_START -->` and `<!-- BACKLINK_END -->` markers
- The `_update_backlinks_for_note()` function manages this section
- When a note is indexed, all affected notes (old and new link targets) have their backlink sections updated

## Common Commands

### Testing/Development
Tests are written using [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System) and located in `test/`:

```bash
# Run all tests
bats test/

# Run specific test file
bats test/unit/common.bats

# Run single test by line number
bats test/unit/common.bats:22
```

**Test Structure:**
- `test/helpers.bash` - Provides `setup_test_env()` and `teardown_test_env()` to create sandboxed environments
- `test/unit/*.bats` - Individual test suites for each command
- Tests use temporary directories and override `ZETTEL_DIR` and `XDG_CONFIG_HOME` to avoid polluting real data

### Running the Tool
```bash
# Make executable
chmod +x zk

# Create symlink to PATH
ln -s "$(pwd)/zk" ~/.local/bin/zk

# Initialize
zk init

# Install shell completion
echo 'source <(zk completion)' >> ~/.bashrc
```

### Key Commands
- `zk add [template]` - Create timestamped note
- `zk journal` - Open/create daily journal
- `zk bookmark` - Interactive bookmark capture
- `zk find` - Full-text search with fzf (default command)
- `zk edit` - Fuzzy find note by filename
- `zk query --tag <tag>` - Structured SQLite queries
- `zk backlinks` - Show backlinks for a note
- `zk index` - Rebuild entire search index

## Development Notes

### macOS Compatibility
- Uses `gnu-sed` when available via `gsed` command
- Handles `stat` command differences between macOS and Linux (lib/common.sh:121)
- Requires `gstat` from coreutils on macOS for consistent file modification times

### ID Generation
- IDs are 6-character hex strings from `/dev/urandom`
- Collision detection ensures uniqueness (lib/common.sh:18-25)

### Critical Functions
- `_index_file()`: Parses notes and updates all database tables. Called after any note creation or modification.
- `_update_backlinks_for_note()`: Maintains automatic backlink sections. Safe to call multiple times.
- `_ensure_initialized()`: Guards all commands except `init` to ensure database exists.

### tmux Integration
- Search results open in new tmux panes when available
- Falls back to regular editor if not in tmux session

### Wikilink Resolution
Link targets are resolved in this order:
1. Match against note ID
2. Match against note title
3. Match against note aliases

This allows flexible linking like `[[note-title]]` or `[[alias]]` without requiring exact IDs.
