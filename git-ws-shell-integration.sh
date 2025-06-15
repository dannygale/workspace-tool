#!/bin/bash

# Shell integration for git ws workspace management subcommand
# This file should be sourced in your shell profile

git-ws() {
    if [[ "$1" == "open" ]]; then
        local workspace_path=$(command git ws open "$2" 2>/dev/null)
        if [[ $? -eq 0 && -n "$workspace_path" ]]; then
            cd "$workspace_path"
            echo "Changed to workspace: $2"
        else
            command git ws open "$2"
        fi
    elif [[ "$1" == "exit" ]]; then
        # Run the command and capture stdout only, let stderr pass through
        local root_path
        root_path=$(command git ws exit 2>/dev/null)
        local exit_code=$?
        if [[ $exit_code -eq 0 && -n "$root_path" ]]; then
            cd "$root_path"
            echo "Returned to root directory"
        else
            command git ws exit
        fi
    else
        command git ws "$@"
    fi
}

# Also create an alias for convenience
alias gws='git-ws'
