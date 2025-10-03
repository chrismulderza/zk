# Simple (Shell) ZettleKasten

A ZettleKasten developed using only the bash shell and standard tools available
on Linux and macOS.

# Why?

I wanted a portable system that will work across different systems. There are a
number of tools like [Obsidian](https://obsidian.md) or [zk-org](https://zk-org.github.io),
but they don't satisfy my goals.

# What?

The ZettleKasten or PKM system has to remove as much friction as possible from
building out and/or capturing knowledge.

All notes to be captured using Markdown with YAML front matter.

# Dependencies

- tmux, will provide the windowing and menu system through popups, menus and
  pane management.
- fzf, for fuzzy finding and searching
- ripgrep (rg), to augment searching throught files and possibly facilitating
  full text search.
- sqlite, potential indexing system
- jq
- yq
- dasel???

# Requirements

- templating
- search by tag
- ability to manage note types
- pre/post hook system on note create/update/delete
- shell completion
- context aware, multiple PKB support

# Observations

I'm getting the feeling that there's a bigger capability lurking here using tmux
as a window controller. Something I'm thinking of is some vim trickery/keymap
that would "run" commands in a code block in another window using `tmux
send-keys`.

Right now I'm also looking at tmux menus, popups and send-keys to bind a
shortcut to add a task for example. Bonus points for "syncing" a task added in a
markdown document to Taskwarrior.

Also need to look at how Treesitter (AST) might help to build the markdown
indexing system.
