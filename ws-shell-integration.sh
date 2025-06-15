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
        # Smart path-based detection: look for workspaces directory in current path
        local current_dir=$(pwd)
        
        # Check if we're in a path that contains /workspaces/
        if [[ "$current_dir" == */workspaces/* ]]; then
            # Extract the root directory (everything before /workspaces/)
            local root_dir="${current_dir%%/workspaces/*}"
            cd "$root_dir"
            echo "Returned to root directory"
        else
            # Not in a workspace, just show the message
            command ws exit
        fi
    else
        command ws "$@"
    fi
}
