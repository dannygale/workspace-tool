#!/bin/bash

# Wrapper function for ws open command
# This should be sourced in your shell profile

ws() {
    if [[ "$1" == "open" ]]; then
        local workspace_path=$(./ws open "$2" 2>/dev/null)
        if [[ $? -eq 0 && -n "$workspace_path" ]]; then
            cd "$workspace_path"
            echo "Changed to workspace: $2"
        else
            ./ws open "$2"
        fi
    else
        ./ws "$@"
    fi
}
