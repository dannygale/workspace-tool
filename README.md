# Workspace Management Tool (`ws`)

Create workspaces in your git projects to work on multiple branches simultaneously. Especially helpful for working with
several coding agents working on different things. 

Available as both a standalone command (`ws`) and a git subcommand (`git ws`).

## Features

- **Create workspaces**: Set up new feature branches in isolated directories (always in git repository root)
- **Navigate workspaces**: Quickly change to workspace directories
- **Fetch branches**: Pull feature branches from remote repositories
- **Finish features**: Merge feature branches into develop
- **Clean up**: Remove workspaces with safety checks
- **List workspaces**: View all existing workspaces
- **Git integration**: Use as `git ws` subcommand for seamless git workflow
- **Tab completion**: Smart tab completion for commands and workspace names in both Bash and Zsh
- **Location independent**: Works from any directory within the git repository

## Installation

### Quick Install (Recommended)
```bash
./install-ws.sh
```

The install script will:
- Install the `ws` command to `~/.local/bin/`
- Install the `git ws` subcommand to `~/.local/bin/`
- Install shell integration for `ws open`/`ws exit` and `git ws open`/`git ws exit` commands
- Install tab completion for both `ws` and `git ws` commands in Bash and Zsh
- Automatically add sourcing to your shell profile (`.bashrc`, `.zshrc`, etc.)
- Provide instructions for any manual steps needed

After installation, restart your terminal or source your profile:
```bash
# For bash users
source ~/.bashrc

# For zsh users  
source ~/.zshrc
```

### Manual Install
1. Copy `ws` to a directory in your PATH (e.g., `~/.local/bin/`)
2. Copy `git-ws` to the same directory in your PATH
3. Make both executable: `chmod +x ~/.local/bin/ws ~/.local/bin/git-ws`
4. Copy `ws-shell-integration.sh` and `git-ws-shell-integration.sh` to the same directory
5. Add sourcing for both files to your shell profile

### Shell Integration
The shell integration enables `ws open`/`git ws open` to change your current directory and `ws exit`/`git ws exit` to return to the project root. This is automatically set up by the install script, but if you need to add it manually:

```bash
# Add these lines to your ~/.bashrc, ~/.zshrc, or equivalent
source ~/.local/bin/ws-shell-integration.sh
source ~/.local/bin/git-ws-shell-integration.sh
```

## Usage

All commands work with both `ws` and `git ws`. Examples below show both forms:

### Create a new workspace
```bash
ws new my-feature
# or
git ws new my-feature
```
This will:
- Create `workspaces/my-feature/` directory
- Clone the repository from the develop branch in the current directory
- Create and checkout `feature/my-feature` branch

### Open a workspace
```bash
ws open my-feature
# or
git ws open my-feature
```
Changes your current directory to the workspace (requires shell function setup).

### Exit a workspace
```bash
ws exit
# or
git ws exit
```
Returns to the root project directory if you're currently in a workspace directory (requires shell function setup).

### Fetch a feature branch
```bash
ws fetch my-feature
# or
git ws fetch my-feature
```
Fetches the `feature/my-feature` branch from the remote repository.

### Finish a feature
```bash
ws finish my-feature
# or
git ws finish my-feature
```
This will:
- Fetch latest changes
- Switch to develop branch and pull latest
- Merge the feature branch into develop
- Push the updated develop branch

### Remove a workspace
```bash
ws rm my-feature
# or
git ws rm my-feature
```
Deletes the workspace directory. If the feature branch hasn't been merged into develop, it will ask for confirmation.

### List all workspaces
```bash
ws list
# or
git ws list
```
Shows all existing workspaces and their associated feature branches.

## Tab Completion

Both `ws` and `git ws` support intelligent tab completion:

### Command Completion
```bash
ws <TAB>
# Shows: new open fetch finish rm remove delete list ls exit help

git ws <TAB>  
# Shows: new open fetch finish rm remove delete list ls exit help
```

### Workspace Name Completion
```bash
ws open <TAB>
# Shows your existing workspace names

ws rm <TAB>
# Shows your existing workspace names

git ws fetch <TAB>
# Shows your existing workspace names
```

The completion automatically discovers workspaces and only shows relevant options based on the command context. See [TAB_COMPLETION.md](TAB_COMPLETION.md) for detailed information.

## Directory Structure

The tool creates workspaces in the following structure (always at the git repository root):
```
git-repository-root/
├── workspaces/
│   ├── feature-1/          # Full git repository
│   ├── feature-2/          # Full git repository
│   └── another-feature/    # Full git repository
├── ws                      # The workspace management tool
└── other-project-files...
```

**Note**: Workspaces are always created in the git repository root's `workspaces/` directory, regardless of where you run the `ws` command from within the repository.

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

### `ws open` or `git ws open` doesn't change directory
Make sure the shell integration is properly sourced. Check if the lines are in your shell profile and reload it:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### `ws exit` or `git ws exit` doesn't change directory
The `exit` command also requires the shell integration. Make sure you've sourced both integration files in your shell profile.

### Permission denied
Make sure the scripts are executable:
```bash
chmod +x ~/.local/bin/ws ~/.local/bin/git-ws
```

### Command not found
Ensure the scripts are in your PATH or use the full path to execute them. The install script should handle this automatically.
# Test change from workspace
