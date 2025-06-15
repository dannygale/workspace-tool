#!/bin/bash

# Workspace Management Tool
# Provides ergonomic commands for managing git workspaces

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Find the git repository root
find_git_root() {
    local current_dir="$(pwd)"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.git" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    # If no .git directory found, check if we're in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git rev-parse --show-toplevel
        return 0
    fi
    
    log_error "Not in a git repository"
    exit 1
}

BASEDIR=$(find_git_root)
WORKSPACES_DIR="$BASEDIR/workspaces"

show_usage() {
    cat << EOF
Workspace Management Tool

Usage: ws <command> [arguments]

Commands:
  new|create [name] [base-branch]  Create a new workspace with feature branch (default: develop)
  open|cd [name]                   Change directory to the specified workspace
  fetch [name]                     Fetch the feature branch from workspace to main repository
  finish [name]                    Fetch feature branch from workspace and merge into develop
  rm [name]                        Delete the workspace (with confirmation if not merged)
  list                             List all existing workspaces
  exit                             Return to root directory if currently in a workspace
  help                             Show this help message

Examples:
  ws new my-feature                # Creates workspace from develop branch
  ws create my-feature main       # Creates workspace from main branch (using alias)
  ws open my-feature               # Opens workspace
  ws cd my-feature                 # Opens workspace (using alias)
  ws fetch my-feature              # Brings changes from workspace back to main repo
  ws finish my-feature             # Fetches from workspace and merges into develop
  ws rm my-feature
  ws exit
EOF
}

validate_workspace_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        log_error "Workspace name is required"
        exit 1
    fi
    
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Workspace name can only contain letters, numbers, hyphens, and underscores"
        exit 1
    fi
}

workspace_exists() {
    local name="$1"
    [[ -d "$WORKSPACES_DIR/$name" ]]
}

get_workspace_path() {
    local name="$1"
    echo "$WORKSPACES_DIR/$name"
}

get_branch_name() {
    local name="$1"
    echo "feature/$name"
}

# Command implementations
cmd_new() {
    local name="$1"
    local base_branch="${2:-develop}"  # Default to develop, allow override
    
    validate_workspace_name "$name"
    
    local workspace_path=$(get_workspace_path "$name")
    local branch_name=$(get_branch_name "$name")
    
    if workspace_exists "$name"; then
        log_error "Workspace '$name' already exists"
        exit 1
    fi
    
    log_info "Creating workspace '$name' from branch '$base_branch'..."
    
    # Create workspace directory
    mkdir -p "$workspace_path"
    cd "$workspace_path"
    
    # Clone repo from specified base branch
    log_info "Cloning repository from '$base_branch' branch..."
    if git clone -b "$base_branch" "$BASEDIR" .; then
        log_success "Successfully cloned from '$base_branch' branch"
    else
        log_error "Failed to clone from '$base_branch' branch"
        log_error "Make sure the '$base_branch' branch exists"
        cd "$BASEDIR"
        rm -rf "$workspace_path"
        exit 1
    fi
    
    # Create and checkout feature branch
    log_info "Creating feature branch '$branch_name'..."
    git branch "$branch_name"
    git checkout "$branch_name"
    
    log_success "Workspace '$name' created successfully"
    log_info "Base branch: $base_branch"
    log_info "Feature branch: $branch_name"
    log_info "Path: $workspace_path"
}

cmd_open() {
    local name="$1"
    validate_workspace_name "$name"
    
    if ! workspace_exists "$name"; then
        log_error "Workspace '$name' does not exist"
        exit 1
    fi
    
    local workspace_path=$(get_workspace_path "$name")
    
    # Since we can't change the parent shell's directory from a script,
    # we'll provide the path for the user to cd to
    echo "$workspace_path"
}

cmd_fetch() {
    local name="$1"
    validate_workspace_name "$name"
    
    if ! workspace_exists "$name"; then
        log_error "Workspace '$name' does not exist"
        exit 1
    fi
    
    local workspace_path=$(get_workspace_path "$name")
    local branch_name=$(get_branch_name "$name")
    
    log_info "Fetching branch '$branch_name' from workspace '$name' to main repository..."
    
    # Work in the main repository, not the workspace
    cd "$BASEDIR"
    
    # Fetch the feature branch from the workspace directory
    log_info "Fetching changes from workspace..."
    if git fetch "$workspace_path" "$branch_name:$branch_name" 2>/dev/null; then
        log_success "Successfully fetched branch '$branch_name' from workspace"
    else
        # If direct fetch fails, try adding workspace as a temporary remote
        log_info "Direct fetch failed, trying alternative method..."
        
        # Add workspace as temporary remote
        local temp_remote="workspace-$name"
        git remote add "$temp_remote" "$workspace_path" 2>/dev/null || true
        
        # Fetch from temporary remote
        if git fetch "$temp_remote" "$branch_name:$branch_name"; then
            log_success "Successfully fetched branch '$branch_name' from workspace"
        else
            log_error "Failed to fetch branch '$branch_name' from workspace"
            git remote remove "$temp_remote" 2>/dev/null || true
            exit 1
        fi
        
        # Clean up temporary remote
        git remote remove "$temp_remote" 2>/dev/null || true
    fi
}

cmd_finish() {
    local name="$1"
    validate_workspace_name "$name"
    
    if ! workspace_exists "$name"; then
        log_error "Workspace '$name' does not exist"
        exit 1
    fi
    
    local workspace_path=$(get_workspace_path "$name")
    local branch_name=$(get_branch_name "$name")
    
    log_info "Finishing workspace '$name'..."
    
    # Work in the main repository, not the workspace
    cd "$BASEDIR"
    
    # First, fetch the latest changes from the workspace
    log_info "Fetching latest changes from workspace..."
    local temp_remote="workspace-$name"
    git remote add "$temp_remote" "$workspace_path" 2>/dev/null || true
    
    if git fetch "$temp_remote" "$branch_name:$branch_name"; then
        log_success "Fetched latest changes from workspace"
    else
        log_error "Failed to fetch changes from workspace"
        git remote remove "$temp_remote" 2>/dev/null || true
        exit 1
    fi
    
    # Clean up temporary remote
    git remote remove "$temp_remote" 2>/dev/null || true
    
    # Switch to develop and pull latest from origin
    log_info "Updating develop branch from origin..."
    git checkout develop
    git pull origin develop
    
    # Merge feature branch
    log_info "Merging '$branch_name' into develop..."
    if git merge "$branch_name" --no-ff -m "Merge $branch_name into develop"; then
        log_success "Successfully merged '$branch_name' into develop"
        
        # Push develop branch to origin
        log_info "Pushing develop branch to origin..."
        git push origin develop
        
        log_success "Workspace '$name' finished successfully"
        log_info "The feature branch '$branch_name' is now merged into develop"
    else
        log_error "Failed to merge '$branch_name' into develop"
        log_error "Please resolve conflicts manually"
        exit 1
    fi
}

cmd_rm() {
    local name="$1"
    validate_workspace_name "$name"
    
    if ! workspace_exists "$name"; then
        log_error "Workspace '$name' does not exist"
        exit 1
    fi
    
    local workspace_path=$(get_workspace_path "$name")
    local branch_name=$(get_branch_name "$name")
    
    # Check if branch has been merged
    cd "$workspace_path"
    
    # Fetch latest to ensure we have up-to-date info
    git fetch origin develop 2>/dev/null || true
    
    # Check if feature branch is merged into develop
    local is_merged=false
    if git merge-base --is-ancestor "$branch_name" origin/develop 2>/dev/null; then
        is_merged=true
    fi
    
    if [[ "$is_merged" == "false" ]]; then
        log_warning "Branch '$branch_name' has not been merged into develop"
        echo -n "Are you sure you want to delete workspace '$name'? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Deletion cancelled"
            exit 0
        fi
    fi
    
    log_info "Deleting workspace '$name'..."
    cd "$BASEDIR"
    rm -rf "$workspace_path"
    
    log_success "Workspace '$name' deleted successfully"
}

cmd_list() {
    if [[ ! -d "$WORKSPACES_DIR" ]]; then
        log_info "No workspaces directory found"
        return
    fi
    
    local workspaces=($(ls -1 "$WORKSPACES_DIR" 2>/dev/null || true))
    
    if [[ ${#workspaces[@]} -eq 0 ]]; then
        log_info "No workspaces found"
        return
    fi
    
    echo "Existing workspaces:"
    for workspace in "${workspaces[@]}"; do
        local workspace_path="$WORKSPACES_DIR/$workspace"
        if [[ -d "$workspace_path" ]]; then
            local branch_name=$(get_branch_name "$workspace")
            echo "  • $workspace ($branch_name)"
        fi
    done
}

cmd_exit() {
    local current_dir=$(pwd)
    local root_dir=""
    
    # Find the root directory by looking for the ws script
    local search_dir="$current_dir"
    while [[ "$search_dir" != "/" ]]; do
        if [[ -f "$search_dir/ws" ]]; then
            root_dir="$search_dir"
            break
        fi
        search_dir=$(dirname "$search_dir")
    done
    
    if [[ -z "$root_dir" ]]; then
        log_error "Could not find root directory (no 'ws' script found in parent directories)"
        exit 1
    fi
    
    # Check if we're currently in a workspace directory
    local workspaces_dir="$root_dir/workspaces"
    if [[ "$current_dir" == "$workspaces_dir"* ]]; then
        # We're in a workspace, return the root directory path
        echo "$root_dir"
    else
        log_info "Already in root directory or not in a workspace"
        echo "$current_dir"
    fi
}

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        new|create)
            cmd_new "$@"
            ;;
        open|cd)
            cmd_open "$@"
            ;;
        fetch)
            cmd_fetch "$@"
            ;;
        finish)
            cmd_finish "$@"
            ;;
        rm|remove|delete)
            cmd_rm "$@"
            ;;
        list|ls)
            cmd_list "$@"
            ;;
        exit)
            cmd_exit "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
