#!/usr/bin/env bash

function _help() {
    echo "completion        Generate the bash completion script."
}

function cmd_completion() {
    # Expand tilde (~) to the full home directory path for robustness
    local expanded_template_dir
    expanded_template_dir=$(${EVAL} echo "$ZK_TEMPLATE_DIR")
    local expanded_db_file
    expanded_db_file=$(${EVAL} echo "$DB_FILE")

    # Use a quoted heredoc and pipe to sed for safe substitution of paths.
    ${CAT} <<'EOF' | ${SED} \
        -e "s|__ZK_TEMPLATE_DIR__|${expanded_template_dir}|g" \
        -e "s|__ZK_DB_FILE__|${expanded_db_file}|g"
# Bash completion for zk
#
# To install, add the following to your .bashrc or .bash_profile:
#   source <(zk completion)
#
# Or, save it to a file and source it:
#   zk completion > ~/.bash_completion.d/zk
#   # (and ensure your .bashrc sources files from .bash_completion.d)

_zk_completions() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local commands="init add journal bookmark tags edit find query index help completion backlinks"

    # Completion for the main command (first word)
    if [ "${cword}" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
        return 0
    fi

    local command="${words[1]}"
    case "${command}" in
        add)
            # Complete template names for the 'add' command
            local template_dir="__ZK_TEMPLATE_DIR__"
            if [ -d "${template_dir}" ]; then
                local templates=$(ls -1 "${template_dir}" 2>/dev/null | sed 's/\.md$//')
                COMPREPLY=( $(compgen -W "${templates}" -- "${cur}") )
            fi
            ;;
        query)
            # Complete options for the 'query' command
            if [ "${cword}" -eq 2 ]; then
                local query_opts="--tag --alias --type --fulltext"
                COMPREPLY=( $(compgen -W "${query_opts}" -- "${cur}") )
                return 0
            fi

            local query_opt="${words[2]}"
            # Complete values for the query options
            if [ "${cword}" -eq 3 ]; then
                local db_file="__ZK_DB_FILE__"
                
                # Only attempt to query the DB if it exists
                if [ ! -f "${db_file}" ]; then
                    return 0
                fi

                case "${query_opt}" in
                    --tag|-t)
                        local tags=$(sqlite3 "${db_file}" "SELECT DISTINCT tag FROM tags ORDER BY tag")
                        COMPREPLY=( $(compgen -W "${tags}" -- "${cur}") )
                        ;;
                    --alias|-a)
                        # Read aliases line by line to handle spaces correctly
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

EOF
}