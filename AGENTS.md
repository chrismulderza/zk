# AGENTS.md

Quick reference for AI coding agents working in this repository.

## Testing

```bash
bats test/                    # Run all tests
bats test/unit/common.bats    # Run specific test file
bats test/unit/common.bats:22 # Run single test by line number
```

## Code Style

- **Language**: Pure Bash (no external interpreters)
- **Comments**: Comment functions and files.
- **Naming**: `cmd_<name>()` for command functions, `_private_func()` for helpers
- **Variables**: `UPPERCASE_WITH_UNDERSCORES` for globals/config, `lowercase_with_underscores` for locals
- **Error handling**: Check return codes, use `set -euo pipefail` in main scripts
- **Quoting**: Always quote variables: `"$variable"`, not `$variable`
- **Formatting**: Do not use One-liners for simple functions, readable multi-line for complex and simple logic
- **External tools**: Use configurable variables (e.g., `${SQLITE3}`, `${SED}`) defined in lib/libzk.sh
- **macOS compat**: Use `${STAT}` with `${STAT_MTIME_FLAG}`, prefer `gsed` when available

## Architecture

- Command router: `zk` (main executable)
- Shared functions/config: `lib/libzk.sh` (sourced by all commands)
- Commands: `cmd/<cmd>.sh` with single `cmd_<name>()` function
- Critical function: `_index_file()` parses YAML frontmatter, updates SQLite, maintains backlinks
