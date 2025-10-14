# TODO

List of outstanding bugs/issues and/or features to be added to this project.

## BUGS/ISSUES

## FEATURES

- Templating
  - [ ] Improve template processing so that the template can describe a default
        path in which it should be created.

- Task Management
  - [ ] Extract all open/uncompleted tasks from notes.
  - [ ] Easy update of task status
  - [ ] TaskWarrior compatible

- Contact Management

- Bookmark Handling

## ROADMAP

I'm getting the feeling that there's a bigger capability lurking here using tmux
as a window controller. Something I'm thinking of is some vim trickery/keymap
that would "run" commands in a code block in another window using `tmux
send-keys`.

Right now I'm also looking at tmux menus, popups and send-keys to bind a
shortcut to add a task for example. Bonus points for "syncing" a task added in a
markdown document to Taskwarrior.
