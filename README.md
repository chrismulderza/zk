# zk: A Minimalist, Command-Line Zettelkasten

**A powerful, text-based personal knowledge management (PKM) system built in Bash, for the command line.**

`zk` is a Zettelkasten and journaling tool that embraces the Unix philosophy. It uses standard, widely available command-line tools to create a fast, portable, and future-proof knowledge base. All your notes are stored as local Markdown files, ensuring you always own your data.

## Overview

This project provides a single script, `zk`, that acts as a complete interface for your knowledge base. It is designed for developers, writers, and thinkers who are comfortable in the terminal and prefer the power and simplicity of text-based tools.

The system is built on a few core principles:

- **Local-First & Text-Based**: All notes are Markdown files on your local disk. You are never locked into a proprietary format or cloud service.
- **Portability**: The entire note collection is a self-contained directory that can be moved, backed up, and version-controlled with tools like Git.
- **Unix Philosophy**: `zk` leverages powerful, dedicated tools like `fzf`, `ripgrep`, and `sqlite` to do their jobs well, acting as the glue that ties them together.
- **Speed & Efficiency**: All actions, from creation to search, are designed to be fast and keyboard-driven, minimizing friction and keeping you in the flow.

## Features

- **Zettelkasten Note Creation**: Quickly create new atomic notes with timestamp-based IDs.
- **Specialized Note Types**: Built-in, dedicated workflows for **daily journals** and **bookmark capture**.
- **Powerful Indexing**: Notes are indexed in an **SQLite** database, enabling fast, metadata-aware searches and full-text search capabilities.
- **Rich Metadata**: Uses YAML frontmatter to store metadata like `id`, `title`, `type`, `tags`, and `aliases`.
- **Interactive Search**: Blazing-fast, interactive full-text search using **ripgrep** and **fzf**.
- **Tmux Integration**: Search results can open in new `tmux` panes for a seamless multi-pane workflow.
- **Modular & Refactored**: The codebase is cleanly separated into a main router and a library of command files.
- **Highly Configurable**: Behavior can be customized through a simple shell configuration file (`~/.config/zk/config.sh`).
- **Shell Completion**: Provides a `completion` command to generate a dynamic Bash completion script for easy command and option discovery.

## Dependencies

`zk` relies on a set of standard, powerful command-line tools. Most are likely already installed on modern Linux systems and are easily available on macOS.

- `bash` (v4.0+ for certain shell features)
- `sqlite3`
- `fzf` (for interactive filtering)
- `ripgrep` (`rg`) (for fast text search)
- `tmux` (for the multi-pane editing feature)
- **(Optional but Recommended)** `bat` (for syntax-highlighted previews in `fzf`; falls back to `cat`)

#### Installation of Dependencies

- **Debian / Ubuntu**:
  ```bash
  sudo apt update
  sudo apt install sqlite3 fzf ripgrep tmux bat
  ```
- **macOS (with Homebrew)**:
  ```bash
  brew install sqlite fzf ripgrep tmux bat gnu-sed
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S sqlite fzf ripgrep tmux bat
  ```

## Installation

1.  **Clone or Download the Project**
    Create a directory for the project and place all the files (`zk` and the `cmd/` and `lib/` directories) inside it.

    ```bash
    git clone <repository_url> ~/zk-pkm
    cd ~/zk-pkm
    ```

    (Or, simply create the `zk/`, `zk/cmd/`, and `zk/lib/` directories and save all the files provided).

2.  **Make the Main Script Executable**

    ```bash
    chmod +x zk
    ```

3.  **Place the Script in your PATH**
    The easiest way is to create a symbolic link to a directory that is already in your system's `$PATH`, like `~/.local/bin`.

    ```bash
    # Ensure ~/.local/bin exists and is in your PATH
    mkdir -p ~/.local/bin

    # Create the symlink
    ln -s "$(pwd)/zk" ~/.local/bin/zk
    ```

## Initial Setup

Before you can start creating notes, you must initialize the system.

1.  **Run the `init` command**:

    ```bash
    zk init
    ```

    This will:
    - Create your main notes directory (default: `~/.zettelkasten`).
    - Create subdirectories for journals and bookmarks.
    - Create the SQLite database file.
    - Create a default configuration file at `~/.config/zk/config.sh`.
    - Create a directory for templates at `~/.config/zk/templates`.

2.  **(Optional) Customize your Configuration**:
    You can edit the newly created configuration file to change the default editor, notes directory, and more.

    ```bash
    vim ~/.config/zk/config.sh
    ```

3.  **(Optional) Install Shell Completion**:
    For a much-improved user experience, install the bash completion script. Add the following line to the end of your `~/.bashrc` or `~/.bash_profile`:

    ```bash
    source <(zk completion)
    ```

    Restart your shell or run `source ~/.bashrc` to enable it.

## Directory Structure

`zk` maintains a clean separation between its application files, your configuration, and your data.

#### Application Structure

```
zk/
├── zk          # The main executable script and command router.
├── cmd/        # Command implementations.
│   ├── init.sh
│   ├── add.sh
│   ├── journal.sh
│   # ... and all other command files.
└── lib/        # Shared library functions.
    └── libzk.sh
```

#### User Data & Configuration Structure

```
~/.zettelkasten/         # Your main notes directory ($ZETTEL_DIR)
├── zettel.db            # The SQLite index database.
├── 20251004-....md      # Your Zettelkasten notes.
├── journal/
│   └── daily/
│       └── 2025-10-04.md
└── resources/
    └── bookmarks/
        └── 20251004-....md

~/.config/zk/             # Configuration directory
├── config.sh            # User configuration overrides.
└── templates/
    ├── note.md          # Default template for 'zk add'.
    ├── journal_daily.md # Default template for 'zk journal'.
    └── bookmark.md      # Default template for 'zk bookmark'.
```

## File Descriptions

#### Application Files

| File                | Description                                                                                                    |
| :------------------ | :------------------------------------------------------------------------------------------------------------- |
| `zk`                | Main entry point. Parses the command and sources the appropriate file from `cmd/`.                             |
| `lib/libzk.sh`      | Core library. Contains all shared helper functions, default variables, and the crucial `_index_file` function. |
| `cmd/init.sh`       | Contains `cmd_init` for setting up the directory structure, database, and config file.                         |
| `cmd/add.sh`        | Contains `cmd_add` for creating new, general-purpose Zettelkasten notes.                                       |
| `cmd/journal.sh`    | Contains `cmd_journal` for the daily journaling workflow.                                                      |
| `cmd/bookmark.sh`   | Contains `cmd_bookmark` for the interactive bookmark capture workflow.                                         |
| `cmd/find.sh`       | Contains `cmd_find` for interactive, full-text search with `rg` and `fzf`.                                     |
| `cmd/query.sh`      | Contains `cmd_query` for searching the SQLite database by metadata (`tag`, `alias`, `type`).                   |
| `cmd/edit.sh`       | Contains `cmd_edit` for finding a note by filename and opening it for editing.                                 |
| `cmd/index.sh`      | Contains `cmd_index` for rebuilding the entire search index.                                                   |
| `cmd/tags.sh`       | Contains `cmd_tags` for listing all unique tags and their counts.                                              |
| `cmd/completion.sh` | Contains `cmd_completion` to generate the dynamic bash completion script.                                      |
| `cmd/help.sh`       | Contains `cmd_help` to display the usage information.                                                          |

## Usage

Below is a summary of all available commands.

- `zk init`
  Initializes the note directory, database, and configuration files. Run this first.

- `zk add [template_name]`
  Creates a new, timestamped Zettelkasten note. It prompts for a title and uses the `note.md` template by default. If a `template_name` is provided, it will use that template from your templates directory.

- `zk journal`
  Creates or opens the daily journal note for the current date. The file is named `YYYY-MM-DD.md` and stored in the journal directory.

- `zk bookmark`
  Initiates an interactive prompt to capture a web bookmark. It asks for a Title, URL, Tags, and Description, then creates a `bookmark` type note.

- `zk find` (or just `zk`)
  The primary search command. Opens a fuzzy search prompt (`fzf`) over the content of all your notes. Selecting a result opens the file in a new `tmux` pane (if available) at the exact line of the match.

- `zk edit`
  Opens a fuzzy search prompt (`fzf`) over all note filenames. Selecting a note opens it for editing.

- `zk query <flag> <term>`
  Performs a structured search against the SQLite database.
  - `zk query --tag bash`: Finds all notes with the tag `bash`.
  - `zk query --alias PKM`: Finds all notes with the alias `PKM`.
  - `zk query --type bookmark`: Finds all notes of type `bookmark`.
  - `zk query --fulltext "search term"`: Performs a full-text search on the index.

- `zk tags`
  Lists all unique tags used across your entire knowledge base and shows a count of how many notes use each tag, sorted by frequency.

- `zk index`
  Wipes and completely rebuilds the SQLite search index. Useful if you've made manual changes to your notes outside the `zk` tool.

- `zk completion`
  Prints the bash completion script to standard output.

- `zk help`
  Displays the help message.
