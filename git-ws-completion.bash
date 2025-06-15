#!/bin/bash

# Tab completion for git ws (Git Workspace Management Tool)

_git_ws_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    local commands="new open fetch finish rm remove delete list ls exit help"
    
    # Function to get existing workspace names
    _get_workspaces() {
        local workspaces_dir
        # Try to find workspaces directory from current location or parent directories
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
        
        if [[ -d "$workspaces_dir" ]]; then
            ls -1 "$workspaces_dir" 2>/dev/null | grep -v '^\.' || true
        fi
    }
    
    # Adjust COMP_CWORD to account for 'git ws' being two words
    # When user types 'git ws <tab>', COMP_CWORD is 2, but we want to treat it as 1
    local effective_cword=$((COMP_CWORD - 1))
    
    # If we're completing the first argument after 'git ws' (the command)
    if [[ $effective_cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi
    
    # If we're completing arguments for specific commands
    case "$prev" in
        open|fetch|finish|rm|remove|delete)
            # These commands take existing workspace names
            local workspaces=$(_get_workspaces)
            COMPREPLY=($(compgen -W "$workspaces" -- "$cur"))
            return 0
            ;;
        new)
            # For 'new' command, don't provide completions (user should type new name)
            return 0
            ;;
        list|ls|exit|help)
            # These commands don't take arguments
            return 0
            ;;
    esac
    
    # Handle cases where the previous word is not the direct command
    # (e.g., when completing the second argument after 'git ws command')
    if [[ $effective_cword -eq 2 ]]; then
        local command="${COMP_WORDS[2]}"  # The ws command is at index 2 (git=0, ws=1, command=2)
        case "$command" in
            open|fetch|finish|rm|remove|delete)
                local workspaces=$(_get_workspaces)
                COMPREPLY=($(compgen -W "$workspaces" -- "$cur"))
                return 0
                ;;
        esac
    fi
    
    return 0
}

# Register the completion function for git ws
complete -F _git_ws_completion git-ws

# Also register for when git calls the ws subcommand
# This handles 'git ws' completion through git's subcommand mechanism
_git_ws() {
    _git_ws_completion
}

# Register with git's completion system if available
if declare -f __git_complete >/dev/null 2>&1; then
    __git_complete git-ws _git_ws_completion
fi
