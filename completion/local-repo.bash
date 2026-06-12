# Bash completion for local-repo.
#
# Source this from your ~/.bashrc:
#   source /path/to/local-repo/completion/local-repo.bash
#
# It also wires up the same completion for the `lr` alias.

_local_repo() {
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local words=("${COMP_WORDS[@]}")
    local cword="${COMP_CWORD}"

    local subcommands="init set-backup create list ls delete rm url status config help"
    local config_subs="set unset path"
    local config_keys="user host port repos-dir"

    if [[ $cword -eq 1 ]]; then
        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "$subcommands" -- "$cur") )
        return
    fi

    local subcmd="${words[1]}"

    case "$subcmd" in
        config)
            if [[ $cword -eq 2 ]]; then
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "$config_subs" -- "$cur") )
                return
            fi
            local config_sub="${words[2]}"
            case "$config_sub" in
                set|unset)
                    if [[ $cword -eq 3 ]]; then
                        # shellcheck disable=SC2207
                        COMPREPLY=( $(compgen -W "$config_keys" -- "$cur") )
                    fi
                    ;;
            esac
            ;;
        delete|rm)
            if [[ "$cur" == -* ]]; then
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "-f --force" -- "$cur") )
            fi
            ;;
        set-backup)
            if [[ "$cur" == -* ]]; then
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "--mirror" -- "$cur") )
            fi
            ;;
    esac
}

complete -F _local_repo local-repo
complete -F _local_repo lr
