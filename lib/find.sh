#!/usr/bin/env bash
function cmd_find() {
    local selection
    selection=$(rg --line-number --no-heading --color=always '.' "$ZETTEL_DIR" | fzf --ansi --delimiter ':' --preview 'bat --style=full --color=always --highlight-line {2} {1}' --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
    if [ -n "$selection" ]; then
        local file_path; file_path=$(echo "$selection" | cut -d: -f1); local line_number; line_number=$(echo "$selection" | cut -d: -f2)
        if [ -n "${TMUX:-}" ]; then tmux split-window -h "vim +${line_number} '${file_path}'"; else vim "+${line_number}" "$file_path"; fi
    fi
}