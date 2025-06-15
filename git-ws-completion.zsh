#compdef git-ws

# Tab completion for git ws (Git Workspace Management Tool) - Zsh version

# Function to get existing workspace names
_git_ws_get_workspaces() {
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
            search_dir=${search_dir:h}
        done
    fi
    
    if [[ -d "$workspaces_dir" ]]; then
        local workspaces=(${workspaces_dir}/*(N:t))
        print -l $workspaces
    fi
}

_git_ws() {
    local context state line
    typeset -A opt_args
    
    _arguments -C \
        '1: :->command' \
        '2: :->argument' \
        '3: :->third_argument' \
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
                    local workspaces=($(_git_ws_get_workspaces))
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
        third_argument)
            case $words[2] in
                new)
                    # For 'new' command's second argument, suggest branch names
                    local branches=($(git branch -a 2>/dev/null | sed 's/^[* ] //' | sed 's/remotes\/origin\///' | sort -u | grep -v '^HEAD' 2>/dev/null || echo "develop main master"))
                    _describe 'base branch' branches
                    ;;
            esac
            ;;
    esac
}

# Only set up completion if compdef is available (in zsh completion context)
if (( $+functions[compdef] )); then
    compdef _git_ws git-ws
fi
