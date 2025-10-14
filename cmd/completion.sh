#!/usr/bin/env bash

#
# Contains the implementation for the 'completion' command.
#

function _help() {
    echo "completion        Generate the bash completion script."
}

function cmd_completion() {
    # This command generates a dynamic bash completion script.
    # The script itself contains the logic to find the active notebook.
    cat <<'EOM'
# Bash completion for zk
#
# To install, add the following to your .bashrc or .bash_profile:
#   source <(zk completion)

_zk_find_notebook_root_for_completion() {
    local dir
    if [ -n "${ZETTEL_DIR:-}" ]; then
        echo "$ZETTEL_DIR"
        return 0
    fi
    
    dir=$(pwd)
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.zk" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$HOME/.zk"
}

_zk_completions() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local commands="init add journal bookmark tags edit find query index help completion backlinks"

    if [ "${cword}" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
        return 0
    fi

    local command="${words[1]}"
    local notebook_root
    notebook_root=$(_zk_find_notebook_root_for_completion)
    
    case "${command}" in
        add)
            local template_dir="$notebook_root/.zk/templates"
            if [ ! -d "$template_dir" ]; then
                : "${XDG_CONFIG_HOME:="$HOME/.config"}"
                template_dir="$XDG_CONFIG_HOME/zk/templates"
            fi
            
            if [ -d "${template_dir}" ]; then
                local templates=$(ls -1 "${template_dir}" 2>/dev/null | sed 's/\.md$//')
                COMPREPLY=( $(compgen -W "${templates}" -- "${cur}") )
            fi
            ;;
        query)
            if [ "${cword}" -eq 2 ]; then
                local query_opts="--tag --alias --type --fulltext"
                COMPREPLY=( $(compgen -W "${query_opts}" -- "${cur}") )
                return 0
            fi

            local query_opt="${words[2]}"
            if [ "${cword}" -eq 3 ]; then
                local db_file="$notebook_root/.zk/zettel.db"
                if [ ! -f "${db_file}" ]; then return 0; fi

                case "${query_opt}" in
                    --tag|-t)
                        local tags=$(sqlite3 "${db_file}" "SELECT DISTINCT tag FROM tags ORDER BY tag")
                        COMPREPLY=( $(compgen -W "${tags}" -- "${cur}") )
                        ;;
                    --alias|-a)
                        local aliases
                        mapfile -t aliases < <(sqlite3 "${db_file}" "SELECT DISTINCT alias FROM aliases ORDER BY alias")
                        COMPREPLY=( $(compgen -W "$(printf "'%s' " "${aliases[@]}")" -- "${cur}") )
                        ;;
                    --type)
                        local types=$(sqlite3 "${db_file}" "SELECT DISTINCT type FROM notes ORDER BY type")
                        COMPREPLY=( $(compgen -W "${types}" -- "${cur}") )
                        ;;
                esac
            fi
            ;;
    esac
}

complete -F _zk_completions zk
EOM
}
