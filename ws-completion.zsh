#compdef ws

# Tab completion for ws (Workspace Management Tool) - Zsh version

_ws() {
    local context state line
    typeset -A opt_args
    
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
            search_dir=${search_dir:h}
        done
        
        if [[ -d "$workspaces_dir" ]]; then
            local workspaces=(${workspaces_dir}/*(N:t))
            print -l $workspaces
        fi
    }
    
    _arguments -C \
        '1: :->command' \
        '2: :->argument' \
        && return 0
    
    case $state in
        command)
            local commands=(
                'new:Create a new workspace with feature branch'
                'open:Change directory to the specified workspace'
                'fetch:Fetch the feature branch from the workspace'
                'finish:Fetch and merge the feature branch into develop'
                'rm:Delete the workspace'
                'remove:Delete the workspace'
                'delete:Delete the workspace'
                'list:List all existing workspaces'
                'ls:List all existing workspaces'
                'exit:Return to root directory if currently in a workspace'
                'help:Show help message'
            )
            _describe 'commands' commands
            ;;
        argument)
            case $words[2] in
                open|fetch|finish|rm|remove|delete)
                    local workspaces=($(_get_workspaces))
                    _describe 'workspaces' workspaces
                    ;;
                new)
                    _message 'workspace name'
                    ;;
                list|ls|exit|help)
                    # No arguments for these commands
                    ;;
            esac
            ;;
    esac
}

_ws "$@"
