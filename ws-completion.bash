#!/bin/bash

# Tab completion for ws (Workspace Management Tool)

_ws_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    local commands="new create open cd fetch finish rm remove delete list ls hooks exit help"
    
    # Function to get existing workspace names
    _get_workspaces() {
        local workspaces_dir
        
        # Try to find git repository root first
        local git_root=""
        if git rev-parse --show-toplevel > /dev/null 2>&1; then
            git_root=$(git rev-parse --show-toplevel)
            workspaces_dir="$git_root/workspaces"
        else
            # Fallback: search from current location up to parent directories
            local search_dir="$(pwd)"
            while [[ "$search_dir" != "/" ]]; do
                if [[ -d "$search_dir/workspaces" ]]; then
                    workspaces_dir="$search_dir/workspaces"
                    break
                elif [[ -f "$search_dir/ws" ]]; then
                    workspaces_dir="$search_dir/workspaces"
                    break
                fi
                search_dir=$(dirname "$search_dir")
            done
        fi
        
        if [[ -d "$workspaces_dir" ]]; then
            ls -1 "$workspaces_dir" 2>/dev/null | grep -v '^\.' || true
        fi
    }
    
    # Function to get available hooks
    _get_hooks() {
        local git_root
        if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
            local hooks_dir="$git_root/workspaces/.hooks"
            if [[ -d "$hooks_dir" ]]; then
                # Find all executable files that are not examples
                for hook_file in "$hooks_dir"/*; do
                    if [[ -f "$hook_file" && -x "$hook_file" && ! "$hook_file" =~ \.example$ ]]; then
                        basename "$hook_file"
                    fi
                done
            fi
        fi
    }
    
    # If we're completing the first argument (command)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi
    
    # If we're completing arguments for specific commands
    case "$prev" in
        open|cd|fetch|finish|rm|remove|delete)
            # These commands take existing workspace names
            local workspaces=$(_get_workspaces)
            COMPREPLY=($(compgen -W "$workspaces" -- "$cur"))
            return 0
            ;;
        new|create)
            # For 'new/create' command, don't provide completions for workspace name (user should type new name)
            return 0
            ;;
        hooks)
            # Hooks subcommands
            local hooks_commands="list ls init create edit help"
            COMPREPLY=($(compgen -W "$hooks_commands" -- "$cur"))
            return 0
            ;;
        list|ls|exit|help)
            # These commands don't take arguments
            return 0
            ;;
    esac
    
    # Handle cases where we're completing the third argument (base branch for 'new/create' command)
    if [[ ${COMP_CWORD} -eq 3 ]]; then
        local command="${COMP_WORDS[1]}"
        case "$command" in
            new|create)
                # For 'new/create' command's second argument, suggest branch names
                local branches=$(git branch -a 2>/dev/null | sed 's/^[* ] //' | sed 's/remotes\/origin\///' | sort -u | grep -v '^HEAD' || echo "develop main master")
                COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                return 0
                ;;
            hooks)
                local hooks_subcommand="${COMP_WORDS[2]}"
                case "$hooks_subcommand" in
                    create)
                        # Hook types for 'hooks create'
                        local hook_types="pre-create post-create pre-finish post-finish pre-delete post-delete"
                        COMPREPLY=($(compgen -W "$hook_types" -- "$cur"))
                        return 0
                        ;;
                    edit)
                        # Available hooks for 'hooks edit'
                        local available_hooks=$(_get_hooks)
                        COMPREPLY=($(compgen -W "$available_hooks" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
        esac
    fi
    
    # Handle cases where we're completing the fourth argument
    if [[ ${COMP_CWORD} -eq 4 ]]; then
        local command="${COMP_WORDS[1]}"
        case "$command" in
            hooks)
                local hooks_subcommand="${COMP_WORDS[2]}"
                case "$hooks_subcommand" in
                    create)
                        # Hook name for 'hooks create <type> <name>' - no completion, user types name
                        return 0
                        ;;
                esac
                ;;
        esac
    fi
    
    # Handle cases where the previous word is not the direct command
    # (e.g., when completing the second argument)
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        local command="${COMP_WORDS[1]}"
        case "$command" in
            open|cd|fetch|finish|rm|remove|delete)
                local workspaces=$(_get_workspaces)
                COMPREPLY=($(compgen -W "$workspaces" -- "$cur"))
                return 0
                ;;
        esac
    fi
    
    return 0
}

# Register the completion function
complete -F _ws_completion ws
