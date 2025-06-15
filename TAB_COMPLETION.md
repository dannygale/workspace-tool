# Tab Completion for ws Commands

This directory includes comprehensive tab completion support for both `ws` and `git ws` commands in both Bash and Zsh shells.

## Features

### Command Completion
- **Primary commands**: `new`, `open`, `fetch`, `finish`, `rm`, `remove`, `delete`, `list`, `ls`, `exit`, `help`
- **Smart context**: Only shows relevant commands based on what you're typing

### Workspace Name Completion
- **Existing workspaces**: Commands like `open`, `fetch`, `finish`, `rm` will complete with existing workspace names
- **Auto-discovery**: Automatically finds workspaces by looking for the `workspaces/` directory in current or parent directories
- **No completion for new**: The `new` command doesn't provide completions since you should type a new workspace name

### Both Command Forms
- **Standalone**: `ws <TAB>` and `ws open <TAB>`
- **Git subcommand**: `git ws <TAB>` and `git ws open <TAB>`

## Installation

The tab completion is automatically installed when you run `./install-ws.sh`. The installer will:

1. Copy completion scripts to `~/.local/bin/`
2. Add sourcing lines to your shell profile (`.bashrc`, `.zshrc`, etc.)
3. Configure both `ws` and `git ws` completion

### Manual Installation

If you need to install manually:

#### For Bash
```bash
# Copy completion files
cp ws-completion.bash ~/.local/bin/
cp git-ws-completion.bash ~/.local/bin/

# Add to your ~/.bashrc
echo 'source ~/.local/bin/ws-completion.bash' >> ~/.bashrc
echo 'source ~/.local/bin/git-ws-completion.bash' >> ~/.bashrc

# Reload your shell
source ~/.bashrc
```

#### For Zsh
```bash
# Copy completion files
cp ws-completion.zsh ~/.local/bin/
cp git-ws-completion.zsh ~/.local/bin/

# Add to your ~/.zshrc
echo 'source ~/.local/bin/ws-completion.zsh' >> ~/.zshrc
echo 'source ~/.local/bin/git-ws-completion.zsh' >> ~/.zshrc

# Reload your shell
source ~/.zshrc
```

## Usage Examples

### Basic Command Completion
```bash
ws <TAB>
# Shows: new open fetch finish rm remove delete list ls exit help

git ws <TAB>
# Shows: new open fetch finish rm remove delete list ls exit help
```

### Workspace Name Completion
```bash
ws open <TAB>
# Shows: feature1 feature2 bugfix (your existing workspaces)

ws rm <TAB>
# Shows: feature1 feature2 bugfix (your existing workspaces)

git ws fetch <TAB>
# Shows: feature1 feature2 bugfix (your existing workspaces)
```

### Smart Context Completion
```bash
ws new <TAB>
# No completions shown (you should type a new name)

ws list <TAB>
# No completions shown (command takes no arguments)
```

## How It Works

### Workspace Discovery
The completion scripts automatically find your workspaces by:
1. Looking for a `workspaces/` directory in the current directory
2. Walking up parent directories to find the project root (where `ws` script exists)
3. Listing subdirectories in the found `workspaces/` directory

### Command Classification
Commands are grouped by their argument requirements:
- **Workspace name required**: `open`, `fetch`, `finish`, `rm`, `remove`, `delete`
- **New name expected**: `new` (no completion provided)
- **No arguments**: `list`, `ls`, `exit`, `help`

### Git Integration
The `git ws` completion works by:
- Registering with git's completion system when available
- Adjusting word indices to account for `git ws` being two words
- Providing the same completions as the standalone `ws` command

## Troubleshooting

### Completion Not Working
1. **Check if sourced**: Make sure the completion scripts are sourced in your shell profile
2. **Restart shell**: After installation, restart your terminal or source your profile
3. **Check PATH**: Ensure `~/.local/bin` is in your PATH
4. **Test manually**: Try sourcing the completion script directly:
   ```bash
   source ~/.local/bin/ws-completion.bash
   ```

### No Workspace Names Shown
1. **Check directory structure**: Make sure you have a `workspaces/` directory with subdirectories
2. **Check location**: Run completion from within your project directory or a workspace
3. **Test discovery**: The completion looks for either:
   - `./workspaces/` directory
   - Parent directory containing `ws` script

### Git Completion Issues
1. **Git completion not installed**: Some systems don't have git completion installed
2. **Different git version**: Older git versions might not support custom subcommand completion
3. **Use standalone**: You can always use `ws` instead of `git ws`

## Testing

You can test the completion functionality:

```bash
# Test the completion scripts
./test-completion.sh

# Test interactively
source ./ws-completion.bash
ws <TAB>
ws open <TAB>
```

## Files

- `ws-completion.bash` - Bash completion for `ws` command
- `git-ws-completion.bash` - Bash completion for `git ws` command  
- `ws-completion.zsh` - Zsh completion for `ws` command
- `git-ws-completion.zsh` - Zsh completion for `git ws` command
- `test-completion.sh` - Simple test script for completion functionality
