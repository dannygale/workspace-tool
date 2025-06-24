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
HOOKS_DIR="$WORKSPACES_DIR/.hooks"

# Hook system for workspace lifecycle events
discover_hooks() {
    local hook_type="$1"
    local hooks=()
    
    if [[ -d "$HOOKS_DIR" ]]; then
        # Look for executable scripts matching the hook type
        for hook_file in "$HOOKS_DIR"/$hook_type-* "$HOOKS_DIR"/$hook_type.*; do
            if [[ -f "$hook_file" && -x "$hook_file" ]]; then
                hooks+=("$hook_file")
            fi
        done
    fi
    
    printf '%s\n' "${hooks[@]}" | sort
}

execute_hooks() {
    local hook_type="$1"
    local workspace_name="$2"
    local workspace_path="$3"
    local branch_name="$4"
    
    local hooks=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && hooks+=("$line")
    done < <(discover_hooks "$hook_type")
    
    if [[ ${#hooks[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_info "Executing $hook_type hooks..."
    
    for hook in "${hooks[@]}"; do
        local hook_name=$(basename "$hook")
        log_info "Running hook: $hook_name"
        
        # Set environment variables for the hook
        export WS_HOOK_TYPE="$hook_type"
        export WS_WORKSPACE_NAME="$workspace_name"
        export WS_WORKSPACE_PATH="$workspace_path"
        export WS_BRANCH_NAME="$branch_name"
        export WS_BASE_DIR="$BASEDIR"
        export WS_WORKSPACES_DIR="$WORKSPACES_DIR"
        
        # Execute the hook
        if "$hook" "$workspace_name" "$workspace_path" "$branch_name" "$BASEDIR"; then
            log_success "Hook '$hook_name' completed successfully"
        else
            log_warning "Hook '$hook_name' failed with exit code $?"
        fi
        
        # Clean up environment variables
        unset WS_HOOK_TYPE WS_WORKSPACE_NAME WS_WORKSPACE_PATH WS_BRANCH_NAME WS_BASE_DIR WS_WORKSPACES_DIR
    done
}

# Create hooks directory if it doesn't exist
ensure_hooks_directory() {
    if [[ ! -d "$HOOKS_DIR" ]]; then
        mkdir -p "$HOOKS_DIR"
        log_info "Created hooks directory: $HOOKS_DIR"
        
        # Create example hooks
        create_example_hooks
    fi
}

create_example_hooks() {
    # Create example post-create hook
    cat > "$HOOKS_DIR/post-create.example" << 'EOF'
#!/bin/bash
# Example post-create hook
# This script runs after a workspace is created
# 
# Available environment variables:
# - WS_HOOK_TYPE: The type of hook (post-create, pre-finish, post-finish, pre-delete, post-delete)
# - WS_WORKSPACE_NAME: Name of the workspace
# - WS_WORKSPACE_PATH: Full path to the workspace directory
# - WS_BRANCH_NAME: Name of the feature branch
# - WS_BASE_DIR: Base directory of the project
# - WS_WORKSPACES_DIR: Directory containing all workspaces
#
# Arguments passed to the script:
# $1 = workspace name
# $2 = workspace path  
# $3 = branch name
# $4 = base directory

echo "🎉 Workspace '$1' created successfully!"
echo "📁 Location: $2"
echo "🌿 Branch: $3"

# Example: Install dependencies in the new workspace
# cd "$2" && npm install

# Example: Set up development environment
# cd "$2" && cp .env.example .env

# Example: Send notification
# curl -X POST "https://hooks.slack.com/..." -d "{'text':'New workspace $1 created'}"
EOF

    # Create example pre-finish hook
    cat > "$HOOKS_DIR/pre-finish.example" << 'EOF'
#!/bin/bash
# Example pre-finish hook
# This script runs before a workspace is finished (merged)

echo "🔍 Running pre-finish checks for workspace '$1'..."

# Example: Run tests before finishing
# cd "$2" && npm test

# Example: Run linting
# cd "$2" && npm run lint

# Example: Check for uncommitted changes
cd "$2"
if ! git diff --quiet; then
    echo "⚠️  Warning: Workspace has uncommitted changes"
    git status --short
fi

echo "✅ Pre-finish checks completed for '$1'"
EOF

    # Create example post-finish hook
    cat > "$HOOKS_DIR/post-finish.example" << 'EOF'
#!/bin/bash
# Example post-finish hook
# This script runs after a workspace is finished (merged)

echo "🎯 Workspace '$1' has been finished and merged!"

# Example: Deploy to staging
# ./deploy-staging.sh

# Example: Update issue tracker
# curl -X POST "https://api.github.com/repos/owner/repo/issues/123/comments" \
#   -d "{'body':'Feature branch $3 has been merged'}"

# Example: Clean up temporary files
# rm -rf "$2/tmp/*"

echo "🚀 Post-finish tasks completed for '$1'"
EOF

    # Create example pre-delete hook
    cat > "$HOOKS_DIR/pre-delete.example" << 'EOF'
#!/bin/bash
# Example pre-delete hook
# This script runs before a workspace is deleted

echo "🗑️  Preparing to delete workspace '$1'..."

# Example: Backup important files
# mkdir -p "$WS_BASE_DIR/backups/$1"
# cp "$2/important-file.txt" "$WS_BASE_DIR/backups/$1/"

# Example: Check if workspace has unmerged changes
cd "$2"
if git log origin/develop..HEAD --oneline | grep -q .; then
    echo "⚠️  Warning: Workspace has unmerged commits"
    git log origin/develop..HEAD --oneline
fi

echo "✅ Pre-delete checks completed for '$1'"
EOF

    # Create example post-delete hook
    cat > "$HOOKS_DIR/post-delete.example" << 'EOF'
#!/bin/bash
# Example post-delete hook
# This script runs after a workspace is deleted

echo "🧹 Workspace '$1' has been deleted"

# Example: Clean up related resources
# docker rmi "workspace-$1" 2>/dev/null || true

# Example: Update tracking systems
# curl -X DELETE "https://api.example.com/workspaces/$1"

# Example: Send notification
# echo "Workspace $1 deleted at $(date)" >> "$WS_BASE_DIR/workspace-log.txt"

echo "✅ Post-delete cleanup completed for '$1'"
EOF

    log_info "Created example hooks in $HOOKS_DIR"
    log_info "To use a hook, copy the .example file and remove the .example extension"
    log_info "Make sure to make the hook executable: chmod +x $HOOKS_DIR/hook-name"
}

# Expand workspace patterns to actual workspace names
expand_workspace_patterns() {
    local patterns=("$@")
    local expanded_names=()
    
    if [[ ! -d "$WORKSPACES_DIR" ]]; then
        return 0
    fi
    
    for pattern in "${patterns[@]}"; do
        # Skip files that exist in current directory but aren't workspaces
        if [[ -f "$pattern" ]]; then
            continue
        fi
        
        # If pattern contains glob characters, expand it in workspaces directory
        if [[ "$pattern" == *"*"* ]] || [[ "$pattern" == *"?"* ]] || [[ "$pattern" == *"["* ]]; then
            # Use shell globbing to expand pattern in workspaces directory
            local matches=()
            local old_pwd=$(pwd)
            cd "$WORKSPACES_DIR"
            
            # Set nullglob to handle no matches gracefully
            shopt -s nullglob
            for match in $pattern; do
                if [[ -d "$match" ]]; then
                    matches+=("$match")
                fi
            done
            shopt -u nullglob
            
            cd "$old_pwd"
            
            if [[ ${#matches[@]} -eq 0 ]]; then
                log_warning "No workspaces match pattern: $pattern"
            else
                expanded_names+=("${matches[@]}")
            fi
        else
            # Direct workspace name
            expanded_names+=("$pattern")
        fi
    done
    
    # Remove duplicates and return
    printf '%s\n' "${expanded_names[@]}" | sort -u
}

# Validate multiple workspace names
validate_workspace_names() {
    local names=("$@")
    local valid_names=()
    local has_errors=false
    
    for name in "${names[@]}"; do
        if [[ -z "$name" ]]; then
            continue
        fi
        
        # Skip validation for glob patterns - they'll be expanded later
        if [[ "$name" == *"*"* ]] || [[ "$name" == *"?"* ]] || [[ "$name" == *"["* ]]; then
            valid_names+=("$name")
            continue
        fi
        
        # Validate individual workspace name
        if validate_workspace_name_silent "$name"; then
            valid_names+=("$name")
        else
            log_error "Invalid workspace name: $name"
            has_errors=true
        fi
    done
    
    if [[ "$has_errors" == "true" ]]; then
        exit 1
    fi
    
    printf '%s\n' "${valid_names[@]}"
}

# Silent version of validate_workspace_name that returns true/false
validate_workspace_name_silent() {
    local name="$1"
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    # Allow glob patterns - they'll be expanded later
    if [[ "$name" == *"*"* ]] || [[ "$name" == *"?"* ]] || [[ "$name" == *"["* ]]; then
        return 0
    fi
    
    # Check for problematic characters (excluding glob characters)
    if [[ "$name" == *"/"* ]] || [[ "$name" == *"\\"* ]] || [[ "$name" == *":"* ]] || \
       [[ "$name" == *"\""* ]] || [[ "$name" == *"'"* ]] || [[ "$name" == *"<"* ]] || \
       [[ "$name" == *">"* ]] || [[ "$name" == *"|"* ]]; then
        return 1
    fi
    
    # Reject names that are just dots
    if [[ "$name" =~ ^\.+$ ]]; then
        return 1
    fi
    
    # Reject empty name or names with only whitespace
    if [[ "$name" =~ ^[[:space:]]*$ ]]; then
        return 1
    fi
    
    return 0
}

show_usage() {
    cat << EOF
Workspace Management Tool

Usage: ws <command> [arguments]

Commands:
  new|create [name] [base-branch]  Create a new workspace with feature branch (default: develop)
  open|cd [name]                   Change directory to the specified workspace
  fetch [name...]                  Fetch feature branches from local workspaces to main repository
  finish [name...]                 Fetch feature branches from workspaces and merge into local develop
  rm [name...]                     Delete workspaces (with confirmation if not merged)
  list                             List all existing workspaces
  hooks                            Manage workspace lifecycle hooks
  exit                             Return to root directory if currently in a workspace
  help                             Show this help message

Multi-workspace operations:
  Commands marked with [...] support multiple workspace names and glob patterns:
  
  ws fetch workspace1 workspace2   # Fetch from multiple workspaces
  ws rm 'test-*'                   # Remove all workspaces starting with 'test-' (note quotes!)
  ws finish 'feature-*' 'bugfix-*' # Finish all feature and bugfix workspaces (note quotes!)
  ws rm workspace1 'test-*' temp   # Mix specific names and patterns

  IMPORTANT: Use quotes around glob patterns to prevent shell expansion!

Hooks system:
  Automatically run custom scripts during workspace lifecycle events:
  
  ws hooks init                    # Initialize hooks with examples
  ws hooks list                    # List all available hooks
  ws hooks create post-create deploy  # Create a new hook
  
  Hook types: pre-create, post-create, pre-finish, post-finish, pre-delete, post-delete

Examples:
  ws new my-feature                # Creates workspace from develop branch
  ws create my-feature main       # Creates workspace from main branch (using alias)
  ws open my-feature               # Opens workspace
  ws cd my-feature                 # Opens workspace (using alias)
  ws fetch my-feature              # Brings changes from local workspace back to main repo
  ws fetch 'feature-*' bugfix-123  # Fetch from multiple workspaces using patterns
  ws finish my-feature             # Fetches from workspace and merges into local develop
  ws rm my-feature                 # Remove single workspace
  ws rm 'test-*' 'temp-*'          # Remove multiple workspaces using patterns
  ws exit

Note: All operations work locally - no remote/origin operations are performed.
EOF
}

validate_workspace_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        log_error "Workspace name is required"
        exit 1
    fi
    
    # Check for problematic characters that would cause issues with filesystem or shell
    # Reject: path separators, shell metacharacters, control characters
    if [[ "$name" == *"/"* ]] || [[ "$name" == *"\\"* ]] || [[ "$name" == *":"* ]] || \
       [[ "$name" == *"*"* ]] || [[ "$name" == *"?"* ]] || [[ "$name" == *"\""* ]] || \
       [[ "$name" == *"'"* ]] || [[ "$name" == *"<"* ]] || [[ "$name" == *">"* ]] || \
       [[ "$name" == *"|"* ]]; then
        log_error "Workspace name contains invalid characters. Avoid: / \\ : * ? \" ' < > |"
        exit 1
    fi
    
    # Reject names that are just dots (., .., etc.) as they have special meaning
    if [[ "$name" =~ ^\.+$ ]]; then
        log_error "Workspace name cannot be just dots (., .., etc.)"
        exit 1
    fi
    
    # Reject empty name or names with only whitespace
    if [[ "$name" =~ ^[[:space:]]*$ ]]; then
        log_error "Workspace name cannot be empty or contain only whitespace"
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
    
    # Ensure hooks directory exists
    ensure_hooks_directory
    
    # Execute pre-create hooks
    execute_hooks "pre-create" "$name" "$workspace_path" "$branch_name"
    
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
    
    # Return to base directory for consistent hook execution
    cd "$BASEDIR"
    
    # Execute post-create hooks
    execute_hooks "post-create" "$name" "$workspace_path" "$branch_name"
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
    if [[ $# -eq 0 ]]; then
        log_error "Workspace name(s) required"
        echo "Usage: ws fetch <workspace-name> [workspace-name2] [pattern...]"
        echo "Examples:"
        echo "  ws fetch my-feature"
        echo "  ws fetch feature-* bugfix-123"
        echo "  ws fetch workspace1 workspace2 workspace3"
        exit 1
    fi
    
    # Validate and expand workspace patterns
    local validated_names=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && validated_names+=("$line")
    done < <(validate_workspace_names "$@")
    
    local expanded_names=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && expanded_names+=("$line")
    done < <(expand_workspace_patterns "${validated_names[@]}")
    
    if [[ ${#expanded_names[@]} -eq 0 ]]; then
        log_error "No workspaces found matching the specified patterns"
        exit 1
    fi
    
    # Check which workspaces actually exist
    local existing_workspaces=()
    local missing_workspaces=()
    
    for name in "${expanded_names[@]}"; do
        if workspace_exists "$name"; then
            existing_workspaces+=("$name")
        else
            missing_workspaces+=("$name")
        fi
    done
    
    # Report missing workspaces
    if [[ ${#missing_workspaces[@]} -gt 0 ]]; then
        for name in "${missing_workspaces[@]}"; do
            log_warning "Workspace '$name' does not exist"
        done
    fi
    
    if [[ ${#existing_workspaces[@]} -eq 0 ]]; then
        log_error "No existing workspaces found"
        exit 1
    fi
    
    # Show what will be fetched
    log_info "Fetching from ${#existing_workspaces[@]} workspace(s):"
    for name in "${existing_workspaces[@]}"; do
        echo "  • $name"
    done
    echo
    
    # Work in the main repository, not the workspace
    cd "$BASEDIR"
    
    # Fetch from each workspace
    local success_count=0
    local failed_workspaces=()
    
    for name in "${existing_workspaces[@]}"; do
        local workspace_path=$(get_workspace_path "$name")
        local branch_name=$(get_branch_name "$name")
        
        log_info "Fetching branch '$branch_name' from local workspace '$name'..."
        
        # Fetch the feature branch from the workspace directory (local operation)
        if git fetch "$workspace_path" "$branch_name:$branch_name" 2>/dev/null; then
            log_success "Successfully fetched branch '$branch_name' from workspace '$name'"
            ((success_count++))
        else
            # If direct fetch fails, try adding workspace as a temporary remote
            log_info "Direct fetch failed for '$name', trying alternative method..."
            
            # Add workspace as temporary remote (still local)
            local temp_remote="workspace-$name"
            git remote add "$temp_remote" "$workspace_path" 2>/dev/null || true
            
            # Fetch from temporary remote (local workspace)
            if git fetch "$temp_remote" "$branch_name:$branch_name" 2>/dev/null; then
                log_success "Successfully fetched branch '$branch_name' from workspace '$name'"
                ((success_count++))
            else
                log_error "Failed to fetch branch '$branch_name' from workspace '$name'"
                failed_workspaces+=("$name")
            fi
            
            # Clean up temporary remote
            git remote remove "$temp_remote" 2>/dev/null || true
        fi
    done
    
    # Summary
    if [[ ${#failed_workspaces[@]} -gt 0 ]]; then
        log_warning "Failed to fetch from ${#failed_workspaces[@]} workspace(s):"
        for name in "${failed_workspaces[@]}"; do
            echo "  • $name"
        done
    fi
    
    log_success "Successfully fetched from $success_count workspace(s)"
}

cmd_finish() {
    if [[ $# -eq 0 ]]; then
        log_error "Workspace name(s) required"
        echo "Usage: ws finish <workspace-name> [workspace-name2] [pattern...]"
        echo "Examples:"
        echo "  ws finish my-feature"
        echo "  ws finish feature-* bugfix-123"
        echo "  ws finish workspace1 workspace2 workspace3"
        exit 1
    fi
    
    # Validate and expand workspace patterns
    local validated_names=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && validated_names+=("$line")
    done < <(validate_workspace_names "$@")
    
    local expanded_names=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && expanded_names+=("$line")
    done < <(expand_workspace_patterns "${validated_names[@]}")
    
    if [[ ${#expanded_names[@]} -eq 0 ]]; then
        log_error "No workspaces found matching the specified patterns"
        exit 1
    fi
    
    # Check which workspaces actually exist
    local existing_workspaces=()
    local missing_workspaces=()
    
    for name in "${expanded_names[@]}"; do
        if workspace_exists "$name"; then
            existing_workspaces+=("$name")
        else
            missing_workspaces+=("$name")
        fi
    done
    
    # Report missing workspaces
    if [[ ${#missing_workspaces[@]} -gt 0 ]]; then
        for name in "${missing_workspaces[@]}"; do
            log_warning "Workspace '$name' does not exist"
        done
    fi
    
    if [[ ${#existing_workspaces[@]} -eq 0 ]]; then
        log_error "No existing workspaces found"
        exit 1
    fi
    
    # Show what will be finished
    log_info "Finishing ${#existing_workspaces[@]} workspace(s):"
    for name in "${existing_workspaces[@]}"; do
        echo "  • $name"
    done
    echo
    
    # Work in the main repository
    cd "$BASEDIR"
    
    # Switch to develop branch
    log_info "Switching to develop branch..."
    if ! git checkout develop; then
        log_error "Failed to switch to develop branch"
        exit 1
    fi
    
    # Process each workspace
    local success_count=0
    local failed_workspaces=()
    
    for name in "${existing_workspaces[@]}"; do
        local workspace_path=$(get_workspace_path "$name")
        local branch_name=$(get_branch_name "$name")
        
        log_info "Processing workspace '$name' (branch: $branch_name)..."
        
        # Execute pre-finish hooks
        execute_hooks "pre-finish" "$name" "$workspace_path" "$branch_name"
        
        # Fetch the feature branch from the workspace directory (local operation)
        log_info "Fetching branch '$branch_name' from workspace '$name'..."
        local temp_remote="workspace-$name"
        git remote add "$temp_remote" "$workspace_path" 2>/dev/null || true
        
        local fetch_success=false
        if git fetch "$temp_remote" "$branch_name:$branch_name" 2>/dev/null; then
            fetch_success=true
        fi
        
        # Clean up temporary remote
        git remote remove "$temp_remote" 2>/dev/null || true
        
        if [[ "$fetch_success" == "false" ]]; then
            log_error "Failed to fetch branch '$branch_name' from workspace '$name'"
            failed_workspaces+=("$name")
            continue
        fi
        
        # Merge the feature branch into develop
        log_info "Merging branch '$branch_name' into develop..."
        if git merge "$branch_name" --no-ff -m "Merge branch '$branch_name' from workspace '$name'"; then
            log_success "Successfully merged branch '$branch_name' into develop"
            ((success_count++))
            
            # Execute post-finish hooks
            execute_hooks "post-finish" "$name" "$workspace_path" "$branch_name"
        else
            log_error "Failed to merge branch '$branch_name' into develop"
            failed_workspaces+=("$name")
            # Reset to clean state for next workspace
            git merge --abort 2>/dev/null || true
        fi
    done
    
    # Summary
    if [[ ${#failed_workspaces[@]} -gt 0 ]]; then
        log_warning "Failed to finish ${#failed_workspaces[@]} workspace(s):"
        for name in "${failed_workspaces[@]}"; do
            echo "  • $name"
        done
    fi
    
    log_success "Successfully finished $success_count workspace(s)"
    if [[ $success_count -gt 0 ]]; then
        log_info "The feature branches are now merged into develop locally"
    fi
}

cmd_rm() {
    if [[ $# -eq 0 ]]; then
        log_error "Workspace name(s) required"
        echo "Usage: ws rm <workspace-name> [workspace-name2] [pattern...]"
        echo "Examples:"
        echo "  ws rm my-feature"
        echo "  ws rm test-* temp-workspace"
        echo "  ws rm workspace1 workspace2 workspace3"
        exit 1
    fi
    
    # Validate and expand workspace patterns
    local validated_names=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && validated_names+=("$line")
    done < <(validate_workspace_names "$@")
    
    local expanded_names=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && expanded_names+=("$line")
    done < <(expand_workspace_patterns "${validated_names[@]}")
    
    if [[ ${#expanded_names[@]} -eq 0 ]]; then
        log_error "No workspaces found matching the specified patterns"
        exit 1
    fi
    
    # Check which workspaces actually exist
    local existing_workspaces=()
    local missing_workspaces=()
    
    for name in "${expanded_names[@]}"; do
        if workspace_exists "$name"; then
            existing_workspaces+=("$name")
        else
            missing_workspaces+=("$name")
        fi
    done
    
    # Report missing workspaces
    if [[ ${#missing_workspaces[@]} -gt 0 ]]; then
        for name in "${missing_workspaces[@]}"; do
            log_warning "Workspace '$name' does not exist"
        done
    fi
    
    if [[ ${#existing_workspaces[@]} -eq 0 ]]; then
        log_error "No existing workspaces found"
        exit 1
    fi
    
    # Show what will be deleted
    log_info "Found ${#existing_workspaces[@]} workspace(s) to delete:"
    for name in "${existing_workspaces[@]}"; do
        echo "  • $name"
    done
    echo
    
    # Check merge status for all workspaces
    local unmerged_workspaces=()
    local merged_workspaces=()
    
    for name in "${existing_workspaces[@]}"; do
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
        
        if [[ "$is_merged" == "true" ]]; then
            merged_workspaces+=("$name")
        else
            unmerged_workspaces+=("$name")
        fi
    done
    
    # Warn about unmerged workspaces
    if [[ ${#unmerged_workspaces[@]} -gt 0 ]]; then
        log_warning "The following workspaces have unmerged branches:"
        for name in "${unmerged_workspaces[@]}"; do
            local branch_name=$(get_branch_name "$name")
            echo "  • $name (branch: $branch_name)"
        done
        echo
        echo -n "Are you sure you want to delete ${#existing_workspaces[@]} workspace(s)? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Deletion cancelled"
            exit 0
        fi
    else
        # All merged, but still confirm for multiple deletions
        if [[ ${#existing_workspaces[@]} -gt 1 ]]; then
            echo -n "Delete ${#existing_workspaces[@]} workspaces? [y/N]: "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_info "Deletion cancelled"
                exit 0
            fi
        fi
    fi
    
    # Delete workspaces
    cd "$BASEDIR"
    local deleted_count=0
    for name in "${existing_workspaces[@]}"; do
        local workspace_path=$(get_workspace_path "$name")
        local branch_name=$(get_branch_name "$name")
        
        # Execute pre-delete hooks
        execute_hooks "pre-delete" "$name" "$workspace_path" "$branch_name"
        
        log_info "Deleting workspace '$name'..."
        if rm -rf "$workspace_path"; then
            log_success "Workspace '$name' deleted successfully"
            ((deleted_count++))
            
            # Execute post-delete hooks
            execute_hooks "post-delete" "$name" "$workspace_path" "$branch_name"
        else
            log_error "Failed to delete workspace '$name'"
        fi
    done
    
    log_success "Deleted $deleted_count workspace(s)"
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

cmd_hooks() {
    local subcommand="$1"
    
    case "$subcommand" in
        list|ls)
            cmd_hooks_list
            ;;
        init)
            cmd_hooks_init
            ;;
        create)
            cmd_hooks_create "$2" "$3" "$4"
            ;;
        edit)
            cmd_hooks_edit "$2"
            ;;
        help|--help|-h|"")
            cmd_hooks_help
            ;;
        *)
            log_error "Unknown hooks subcommand: $subcommand"
            cmd_hooks_help
            exit 1
            ;;
    esac
}

cmd_hooks_help() {
    cat << EOF
Hooks Management

Usage: ws hooks <subcommand> [arguments]

Subcommands:
  list|ls                    List all available hooks
  init                       Initialize hooks directory with examples
  create <type> <name>       Create a new hook script (opens in editor)
  create <type> <name> --no-edit  Create hook without opening editor
  edit <hook-name>           Edit an existing hook script
  help                       Show this help message

Hook Types:
  pre-create                 Runs before workspace creation
  post-create                Runs after workspace creation
  pre-finish                 Runs before workspace finishing (merge)
  post-finish                Runs after workspace finishing (merge)
  pre-delete                 Runs before workspace deletion
  post-delete                Runs after workspace deletion

Examples:
  ws hooks list              # List all hooks
  ws hooks init              # Create example hooks
  ws hooks create post-create deploy    # Create and edit post-create-deploy hook
  ws hooks create pre-finish test --no-edit  # Create hook without opening editor
  ws hooks edit post-create-deploy      # Edit the hook

Hook Execution:
  All hooks execute from the git repository root directory for consistency.
  Hooks can navigate to workspace directories using the provided environment
  variables and arguments.

Hook Environment Variables:
  WS_HOOK_TYPE              Type of hook being executed
  WS_WORKSPACE_NAME         Name of the workspace
  WS_WORKSPACE_PATH         Full path to workspace directory
  WS_BRANCH_NAME            Name of the feature branch
  WS_BASE_DIR               Base directory of the project
  WS_WORKSPACES_DIR         Directory containing all workspaces

Hook Arguments:
  \$1 = workspace name
  \$2 = workspace path
  \$3 = branch name
  \$4 = base directory
EOF
}

cmd_hooks_list() {
    ensure_hooks_directory
    
    echo "Hooks directory: $HOOKS_DIR"
    echo
    
    local hook_types=("pre-create" "post-create" "pre-finish" "post-finish" "pre-delete" "post-delete")
    local found_hooks=false
    
    for hook_type in "${hook_types[@]}"; do
        local hooks=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && hooks+=("$line")
        done < <(discover_hooks "$hook_type")
        
        if [[ ${#hooks[@]} -gt 0 ]]; then
            echo "📋 $hook_type hooks:"
            for hook in "${hooks[@]}"; do
                local hook_name=$(basename "$hook")
                local hook_status="✅ executable"
                if [[ ! -x "$hook" ]]; then
                    hook_status="⚠️  not executable"
                fi
                echo "  • $hook_name ($hook_status)"
            done
            echo
            found_hooks=true
        fi
    done
    
    if [[ "$found_hooks" == "false" ]]; then
        echo "No hooks found. Run 'ws hooks init' to create example hooks."
    fi
    
    # Show example hooks
    local examples=($(ls -1 "$HOOKS_DIR"/*.example 2>/dev/null || true))
    if [[ ${#examples[@]} -gt 0 ]]; then
        echo "📝 Example hooks (copy and remove .example to use):"
        for example in "${examples[@]}"; do
            local example_name=$(basename "$example")
            echo "  • $example_name"
        done
    fi
}

cmd_hooks_init() {
    ensure_hooks_directory
    log_success "Hooks directory initialized with examples"
    echo
    echo "To use a hook:"
    echo "1. Copy an example: cp $HOOKS_DIR/post-create.example $HOOKS_DIR/post-create-deploy"
    echo "2. Edit the hook: \$EDITOR $HOOKS_DIR/post-create-deploy"
    echo "3. Make it executable: chmod +x $HOOKS_DIR/post-create-deploy"
}

cmd_hooks_create() {
    local hook_type="$1"
    local hook_name="$2"
    local no_edit=false
    
    # Check for --no-edit flag in third position
    if [[ "$3" == "--no-edit" ]]; then
        no_edit=true
    fi
    
    if [[ -z "$hook_type" || -z "$hook_name" ]]; then
        log_error "Usage: ws hooks create <type> <name>"
        echo "Example: ws hooks create post-create deploy"
        exit 1
    fi
    
    local valid_types=("pre-create" "post-create" "pre-finish" "post-finish" "pre-delete" "post-delete")
    local is_valid=false
    for valid_type in "${valid_types[@]}"; do
        if [[ "$hook_type" == "$valid_type" ]]; then
            is_valid=true
            break
        fi
    done
    
    if [[ "$is_valid" == "false" ]]; then
        log_error "Invalid hook type: $hook_type"
        echo "Valid types: ${valid_types[*]}"
        exit 1
    fi
    
    ensure_hooks_directory
    
    local hook_file="$HOOKS_DIR/$hook_type-$hook_name"
    
    if [[ -f "$hook_file" ]]; then
        log_error "Hook already exists: $hook_file"
        exit 1
    fi
    
    cat > "$hook_file" << EOF
#!/bin/bash
# $hook_type hook: $hook_name
# This script runs during the $hook_type phase
#
# Available environment variables:
# - WS_HOOK_TYPE: The type of hook ($hook_type)
# - WS_WORKSPACE_NAME: Name of the workspace
# - WS_WORKSPACE_PATH: Full path to the workspace directory
# - WS_BRANCH_NAME: Name of the feature branch
# - WS_BASE_DIR: Base directory of the project
# - WS_WORKSPACES_DIR: Directory containing all workspaces
#
# Arguments passed to the script:
# \$1 = workspace name
# \$2 = workspace path
# \$3 = branch name
# \$4 = base directory

echo "🔧 Running $hook_type hook: $hook_name"
echo "📁 Workspace: \$1"
echo "🌿 Branch: \$3"

# Add your custom logic here
# Example: cd "\$2" && npm install

echo "✅ Hook $hook_name completed"
EOF
    
    chmod +x "$hook_file"
    log_success "Created hook: $hook_file"
    log_info "Hook is executable and ready to use"
    
    # Automatically open in editor if available and not disabled
    if [[ "$no_edit" == "true" ]]; then
        echo "Edit with: \$EDITOR $hook_file"
    elif [[ -n "$EDITOR" ]]; then
        log_info "Opening hook in editor..."
        "$EDITOR" "$hook_file"
    elif command -v nano >/dev/null 2>&1; then
        log_info "Opening hook in nano..."
        nano "$hook_file"
    elif command -v vi >/dev/null 2>&1; then
        log_info "Opening hook in vi..."
        vi "$hook_file"
    else
        echo "Edit with: \$EDITOR $hook_file"
        log_info "No editor found. Set \$EDITOR environment variable for automatic editing."
    fi
}

cmd_hooks_edit() {
    local hook_name="$1"
    
    if [[ -z "$hook_name" ]]; then
        log_error "Usage: ws hooks edit <hook-name>"
        echo "Use 'ws hooks list' to see available hooks"
        exit 1
    fi
    
    local hook_file="$HOOKS_DIR/$hook_name"
    
    if [[ ! -f "$hook_file" ]]; then
        log_error "Hook not found: $hook_file"
        echo "Use 'ws hooks list' to see available hooks"
        exit 1
    fi
    
    local editor="${EDITOR:-nano}"
    "$editor" "$hook_file"
}

cmd_exit() {
    local current_dir=$(pwd)
    
    # Find the git repository root
    local root_dir=$(git rev-parse --show-toplevel 2>/dev/null)
    
    if [[ -z "$root_dir" ]]; then
        log_error "Could not find git repository root (not in a git repository)"
        exit 1
    fi
    
    # Check if we're currently in a workspace directory
    local workspaces_dir="$root_dir/workspaces"
    if [[ "$current_dir" == "$workspaces_dir"* ]]; then
        # We're in a workspace, return the root directory path
        echo "$root_dir"
    else
        echo -e "${BLUE}[INFO]${NC} Already in root directory or not in a workspace" >&2
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
        hooks)
            # Handle hooks subcommands (command has already been shifted out)
            case "$1" in
                list|ls)
                    cmd_hooks_list
                    ;;
                init)
                    cmd_hooks_init
                    ;;
                create)
                    cmd_hooks_create "$2" "$3" "$4"
                    ;;
                edit)
                    cmd_hooks_edit "$2"
                    ;;
                help|--help|-h|"")
                    cmd_hooks_help
                    ;;
                *)
                    if [[ -n "$1" ]]; then
                        log_error "Unknown hooks subcommand: $1"
                    fi
                    cmd_hooks_help
                    exit 1
                    ;;
            esac
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
