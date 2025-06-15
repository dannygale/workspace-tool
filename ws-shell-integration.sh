#!/bin/bash

# Shell integration for ws workspace management tool
# This file should be sourced in your shell profile

ws() {
    if [[ "$1" == "open" ]]; then
        local workspace_path=$(command ws open "$2" 2>/dev/null)
        if [[ $? -eq 0 && -n "$workspace_path" ]]; then
            cd "$workspace_path"
            echo "Changed to workspace: $2"
        else
            command ws open "$2"
        fi
    elif [[ "$1" == "exit" ]]; then
        # Run the command and capture stdout only, let stderr pass through
        local root_path
        root_path=$(command ws exit 2>/dev/null)
        local exit_code=$?
        if [[ $exit_code -eq 0 && -n "$root_path" ]]; then
            cd "$root_path"
            echo "Returned to root directory"
        else
            command ws exit
        fi
    else
        command ws "$@"
    fi
}
