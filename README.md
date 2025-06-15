# Workspace Management Tool (`ws`)

Create workspaces in your git projects to work on multiple branches simultaneously. Especially helpful for working with
several coding agents working on different things. 

## Features

- **Create workspaces**: Set up new feature branches in isolated directories
- **Navigate workspaces**: Quickly change to workspace directories
- **Fetch branches**: Pull feature branches from remote repositories
- **Finish features**: Merge feature branches into develop
- **Clean up**: Remove workspaces with safety checks
- **List workspaces**: View all existing workspaces

## Installation

### Quick Install
```bash
./install-ws.sh
```

### Manual Install
1. Copy `ws` to a directory in your PATH (e.g., `~/.local/bin/`)
2. Make it executable: `chmod +x ~/.local/bin/ws`
3. Add the shell function to your profile for `ws open` functionality

### Shell Function Setup
Add this function to your `~/.bashrc`, `~/.zshrc`, or equivalent:

```bash
ws() {
    if [[ "$1" == "open" ]]; then
        local workspace_path=$(command ws open "$2" 2>/dev/null)
        if [[ $? -eq 0 && -n "$workspace_path" ]]; then
            cd "$workspace_path"
            echo "Changed to workspace: $2"
        else
            command ws open "$2"
        fi
    else
        command ws "$@"
    fi
}
```

## Usage

### Create a new workspace
```bash
ws new my-feature
```
This will:
- Create `workspaces/my-feature/` directory
- Clone the repository from the develop branch in the current directory
- Create and checkout `feature/my-feature` branch

### Open a workspace
```bash
ws open my-feature
```
Changes your current directory to the workspace (requires shell function setup).

### Fetch a feature branch
```bash
ws fetch my-feature
```
Fetches the `feature/my-feature` branch from the remote repository.

### Finish a feature
```bash
ws finish my-feature
```
This will:
- Fetch latest changes
- Switch to develop branch and pull latest
- Merge the feature branch into develop
- Push the updated develop branch

### Remove a workspace
```bash
ws rm my-feature
```
Deletes the workspace directory. If the feature branch hasn't been merged into develop, it will ask for confirmation.

### List all workspaces
```bash
ws list
```
Shows all existing workspaces and their associated feature branches.

## Directory Structure

The tool creates workspaces in the following structure:
```
project-root/
├── workspaces/
│   ├── feature-1/          # Full git repository
│   ├── feature-2/          # Full git repository
│   └── another-feature/    # Full git repository
├── ws                      # The workspace management tool
└── create-workspace.sh     # Original script (can be removed)
```

## Safety Features

- **Input validation**: Workspace names are validated for safe characters
- **Merge detection**: Warns before deleting unmerged workspaces
- **Error handling**: Comprehensive error checking and user-friendly messages
- **Confirmation prompts**: Asks for confirmation on destructive operations

## Requirements

- Bash 4.0+
- Git
- Standard Unix utilities (mkdir, rm, etc.)

## Troubleshooting

### `ws open` doesn't change directory
Make sure you've added the shell function to your profile and reloaded it:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Permission denied
Make sure the script is executable:
```bash
chmod +x /path/to/ws
```

### Command not found
Ensure the script is in your PATH or use the full path to execute it.
