#compdef ws

# Tab completion for ws (Workspace Management Tool) - Zsh version

# Function to get existing workspace names
_ws_get_workspaces() {
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

# Get available hooks for completion
_ws_get_hooks() {
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$git_root" ]]; then
        return
    fi
    
    local hooks_dir="$git_root/workspaces/.hooks"
    if [[ -d "$hooks_dir" ]]; then
        # Find all executable files that are not examples
        local hooks=()
        for hook_file in "$hooks_dir"/*; do
            if [[ -f "$hook_file" && -x "$hook_file" && ! "$hook_file" =~ "\.example$" ]]; then
                hooks+=($(basename "$hook_file"))
            fi
        done
        print -l $hooks
    fi
}

_ws() {
    local context state line
    typeset -A opt_args
    
    _arguments -C \
        '1: :->command' \
        '2: :->argument' \
        '3: :->third_argument' \
        '4: :->fourth_argument' \
        && return 0
    
    case $state in
        command)
            local commands=(
                'new:Create a new workspace with feature branch'
                'create:Create a new workspace with feature branch (alias for new)'
                'open:Change directory to the specified workspace'
                'cd:Change directory to the specified workspace (alias for open)'
                'fetch:Fetch feature branches from workspaces (supports multiple names and patterns)'
                'finish:Fetch and merge feature branches into develop (supports multiple names and patterns)'
                'rm:Delete workspaces (supports multiple names and patterns)'
                'remove:Delete workspaces (supports multiple names and patterns)'
                'delete:Delete workspaces (supports multiple names and patterns)'
                'list:List all existing workspaces'
                'ls:List all existing workspaces'
                'hooks:Manage workspace lifecycle hooks'
                'exit:Return to root directory if currently in a workspace'
                'help:Show help message'
            )
            _describe 'commands' commands
            ;;
        argument)
            case $words[2] in
                open|cd|fetch|finish|rm|remove|delete)
                    local workspaces=($(_ws_get_workspaces))
                    _describe 'workspaces' workspaces
                    ;;
                new|create)
                    _message 'workspace name'
                    ;;
                hooks)
                    # Hooks subcommands
                    local hooks_commands=(
                        'list:List all available hooks'
                        'ls:List all available hooks'
                        'init:Initialize hooks directory with examples'
                        'create:Create a new hook script'
                        'edit:Edit an existing hook script'
                        'help:Show hooks help message'
                    )
                    _describe 'hooks subcommands' hooks_commands
                    ;;
                list|ls|exit|help)
                    # No arguments for these commands
                    ;;
            esac
            ;;
        third_argument)
            case $words[2] in
                new|create)
                    # For 'new/create' command's second argument, suggest branch names
                    local branches=($(git branch -a 2>/dev/null | sed 's/^[* ] //' | sed 's/remotes\/origin\///' | sort -u | grep -v '^HEAD' 2>/dev/null || echo "develop main master"))
                    _describe 'base branch' branches
                    ;;
                hooks)
                    case $words[3] in
                        create)
                            # Hook types for 'hooks create'
                            local hook_types=(
                                'pre-create:Runs before workspace creation'
                                'post-create:Runs after workspace creation'
                                'pre-finish:Runs before workspace finishing (merge)'
                                'post-finish:Runs after workspace finishing (merge)'
                                'pre-delete:Runs before workspace deletion'
                                'post-delete:Runs after workspace deletion'
                            )
                            _describe 'hook types' hook_types
                            ;;
                        edit)
                            # Available hooks for 'hooks edit'
                            local available_hooks=($(_ws_get_hooks))
                            if [[ ${#available_hooks[@]} -gt 0 ]]; then
                                _describe 'available hooks' available_hooks
                            else
                                _message 'no hooks found - run "ws hooks init" first'
                            fi
                            ;;
                        list|ls|init|help)
                            # No arguments for these subcommands
                            ;;
                    esac
                    ;;
            esac
            ;;
        fourth_argument)
            case $words[2] in
                hooks)
                    case $words[3] in
                        create)
                            # Hook name for 'hooks create <type> <name>'
                            _message 'hook name'
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

# Only set up completion if compdef is available (in zsh completion context)
if (( $+functions[compdef] )); then
    compdef _ws ws
fi
