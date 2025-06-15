#!/bin/bash

# Workspace Management Tool
# Provides ergonomic commands for managing git workspaces

set -e

BASEDIR=$(pwd)
WORKSPACES_DIR="$BASEDIR/workspaces"

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

show_usage() {
    cat << EOF
Workspace Management Tool

Usage: ws <command> [arguments]

Commands:
  new [name]     Create a new workspace with feature branch
  open [name]    Change directory to the specified workspace
  fetch [name]   Fetch the feature branch from the workspace
  finish [name]  Fetch and merge the feature branch into develop
  rm [name]      Delete the workspace (with confirmation if not merged)
  list           List all existing workspaces
  help           Show this help message

Examples:
  ws new my-feature
  ws open my-feature
  ws fetch my-feature
  ws finish my-feature
  ws rm my-feature
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
    validate_workspace_name "$name"
    
    local workspace_path=$(get_workspace_path "$name")
    local branch_name=$(get_branch_name "$name")
    
    if workspace_exists "$name"; then
        log_error "Workspace '$name' already exists"
        exit 1
    fi
    
    log_info "Creating workspace '$name'..."
    
    # Create workspace directory
    mkdir -p "$workspace_path"
    cd "$workspace_path"
    
    # Clone repo from develop branch
    log_info "Cloning repository..."
    git clone -b develop "$BASEDIR" .
    
    # Create and checkout feature branch
    log_info "Creating feature branch '$branch_name'..."
    git branch "$branch_name"
    git checkout "$branch_name"
    
    log_success "Workspace '$name' created successfully"
    log_info "Branch: $branch_name"
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
    
    log_info "Fetching branch '$branch_name' from workspace '$name'..."
    
    cd "$workspace_path"
    
    # Fetch the feature branch
    git fetch origin "$branch_name" 2>/dev/null || {
        log_warning "Branch '$branch_name' not found on remote, fetching all branches..."
        git fetch --all
    }
    
    # Check if branch exists locally or remotely
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_info "Updating local branch '$branch_name'..."
        git checkout "$branch_name"
        if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
            git pull origin "$branch_name"
        fi
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        log_info "Checking out remote branch '$branch_name'..."
        git checkout -b "$branch_name" "origin/$branch_name"
    else
        log_error "Branch '$branch_name' not found locally or remotely"
        exit 1
    fi
    
    log_success "Successfully fetched branch '$branch_name'"
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
    
    cd "$workspace_path"
    
    # Fetch latest changes
    log_info "Fetching latest changes..."
    git fetch --all
    
    # Switch to develop and pull latest
    log_info "Updating develop branch..."
    git checkout develop
    git pull origin develop
    
    # Merge feature branch
    log_info "Merging '$branch_name' into develop..."
    if git merge "$branch_name" --no-ff -m "Merge $branch_name into develop"; then
        log_success "Successfully merged '$branch_name' into develop"
        
        # Push develop branch
        log_info "Pushing develop branch..."
        git push origin develop
        
        log_success "Workspace '$name' finished successfully"
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

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        new)
            cmd_new "$@"
            ;;
        open)
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
