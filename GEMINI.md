## Gemini Project Overview: zk

This directory contains `zk`, a minimalist, command-line Zettelkasten and personal knowledge management (PKM) system.

### Core Functionality

- **Text-Based PKM**: `zk` is a system for managing notes, journals, and bookmarks as local Markdown files.
- **Unix Philosophy**: It leverages standard command-line tools like `fzf`, `ripgrep`, and `sqlite` to provide a powerful and efficient user experience.
- **SQLite Indexing**: Note metadata (ID, title, tags, etc.) and full-text content are indexed in an SQLite database for fast, structured queries.
- **YAML Frontmatter**: All notes use YAML frontmatter to store metadata.
- **Templates**: New notes are created from templates, which can be customized by the user.

### Project Structure

The project is organized into a main executable script (`zk`) and a library of command files (`lib/`).

- `zk`: The main entry point and command router. It parses the user's command and sources the appropriate file from the `lib/` directory.
- `lib/`: Contains the implementation of each command (e.g., `add.sh`, `find.sh`, `journal.sh`).
- `lib/common.sh`: The core of the application. It contains shared helper functions, default variable definitions, and the crucial `_index_file` function that handles all SQLite database interactions.

### Building and Running

This is a shell script-based project, so there is no compilation or build process.

**1. Installation:**

The `README.md` provides detailed installation instructions. The basic steps are:
- Clone the repository.
- Make the `zk` script executable (`chmod +x zk`).
- Place the `zk` script in your system's `$PATH`.

**2. Initialization:**

Before first use, the system must be initialized with the following command:

```bash
zk init
```

This command creates the notes directory, the SQLite database, and default configuration and template files.

**3. Running:**

Once initialized, you can use the `zk` command to manage your notes. For example:

- `zk add`: Create a new note.
- `zk journal`: Create or open today's journal entry.
- `zk find`: Interactively search for notes.
- `zk query --tag <tag>`: Find all notes with a specific tag.

### Development Conventions

- **Modularity**: Each command is implemented in its own file in the `lib/` directory.
- **ShellCheck**: The scripts are written in Bash and appear to be clean and well-formatted. It is recommended to use `shellcheck` to lint any changes.
- **YAML Frontmatter**: All notes must contain a YAML frontmatter block with at least an `id` field.
- **Database Schema**: The database schema is defined in the `db_init` function in `lib/common.sh`. Any changes to the database schema should be made there.
