#!/bin/bash

# Installation script for the ws workspace management tool

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
SHELL_INTEGRATION_FILE="$INSTALL_DIR/ws-shell-integration.sh"
GIT_SHELL_INTEGRATION_FILE="$INSTALL_DIR/git-ws-shell-integration.sh"

echo "Installing workspace management tool..."

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy the main script
cp "$SCRIPT_DIR/ws" "$INSTALL_DIR/ws"
chmod +x "$INSTALL_DIR/ws"

echo "✓ Installed ws to $INSTALL_DIR/ws"

# Copy the git subcommand
cp "$SCRIPT_DIR/git-ws" "$INSTALL_DIR/git-ws"
chmod +x "$INSTALL_DIR/git-ws"

echo "✓ Installed git-ws to $INSTALL_DIR/git-ws"

# Copy the shell integration files
cp "$SCRIPT_DIR/ws-shell-integration.sh" "$SHELL_INTEGRATION_FILE"
echo "✓ Installed shell integration to $SHELL_INTEGRATION_FILE"

cp "$SCRIPT_DIR/git-ws-shell-integration.sh" "$GIT_SHELL_INTEGRATION_FILE"
echo "✓ Installed git shell integration to $GIT_SHELL_INTEGRATION_FILE"

# Function to add sourcing to a profile file
add_to_profile() {
    local profile_file="$1"
    local ws_source_line="source \"$SHELL_INTEGRATION_FILE\""
    local git_source_line="source \"$GIT_SHELL_INTEGRATION_FILE\""
    
    if [[ -f "$profile_file" ]]; then
        local added_something=false
        
        # Check and add ws integration
        if ! grep -q "ws-shell-integration.sh" "$profile_file"; then
            echo "" >> "$profile_file"
            echo "# ws workspace management tool shell integration" >> "$profile_file"
            echo "$ws_source_line" >> "$profile_file"
            added_something=true
        fi
        
        # Check and add git ws integration
        if ! grep -q "git-ws-shell-integration.sh" "$profile_file"; then
            if [[ "$added_something" == false ]]; then
                echo "" >> "$profile_file"
            fi
            echo "# git ws workspace management subcommand shell integration" >> "$profile_file"
            echo "$git_source_line" >> "$profile_file"
            added_something=true
        fi
        
        if [[ "$added_something" == true ]]; then
            echo "✓ Added sourcing to $profile_file"
            return 0
        else
            echo "✓ Shell integration already configured in $profile_file"
            return 2  # Different return code to indicate already present
        fi
    fi
    return 1
}

# Detect shell and add to appropriate profile
SHELL_NAME=$(basename "$SHELL")
ADDED_TO_PROFILE=false
ALREADY_CONFIGURED=false

case "$SHELL_NAME" in
    bash)
        if add_to_profile "$HOME/.bashrc"; then
            ADDED_TO_PROFILE=true
        elif [[ $? -eq 2 ]]; then
            ALREADY_CONFIGURED=true
        elif add_to_profile "$HOME/.bash_profile"; then
            ADDED_TO_PROFILE=true
        elif [[ $? -eq 2 ]]; then
            ALREADY_CONFIGURED=true
        fi
        ;;
    zsh)
        if add_to_profile "$HOME/.zshrc"; then
            ADDED_TO_PROFILE=true
        elif [[ $? -eq 2 ]]; then
            ALREADY_CONFIGURED=true
        fi
        ;;
    fish)
        # Fish shell has different syntax, provide manual instructions
        echo "⚠️  Fish shell detected. Please manually add the following to your config:"
        echo "   function ws --wraps=ws"
        echo "       if test \$argv[1] = 'open'"
        echo "           set workspace_path (command ws open \$argv[2] 2>/dev/null)"
        echo "           if test \$status -eq 0 -a -n \"\$workspace_path\""
        echo "               cd \$workspace_path"
        echo "               echo \"Changed to workspace: \$argv[2]\""
        echo "           else"
        echo "               command ws open \$argv[2]"
        echo "           end"
        echo "       else if test \$argv[1] = 'exit'"
        echo "           set root_path (command ws exit 2>/dev/null)"
        echo "           if test \$status -eq 0 -a -n \"\$root_path\""
        echo "               cd \$root_path"
        echo "               echo \"Returned to root directory\""
        echo "           else"
        echo "               command ws exit"
        echo "           end"
        echo "       else"
        echo "           command ws \$argv"
        echo "       end"
        echo "   end"
        ;;
    *)
        echo "⚠️  Unknown shell: $SHELL_NAME"
        ;;
esac

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo
    echo "⚠️  $HOME/.local/bin is not in your PATH"
    echo "Add the following line to your shell profile:"
    echo
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
fi

# Final instructions
echo
if [[ "$ADDED_TO_PROFILE" == true ]]; then
    echo "✅ Installation complete!"
    echo "Please restart your terminal or run:"
    case "$SHELL_NAME" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "   source ~/.bashrc"
            else
                echo "   source ~/.bash_profile"
            fi
            ;;
        zsh)
            echo "   source ~/.zshrc"
            ;;
    esac
    echo
    echo "Then you can use 'ws open <workspace>' or 'git ws open <workspace>' to change directories automatically."
elif [[ "$ALREADY_CONFIGURED" == true ]]; then
    echo "✅ Installation complete!"
    echo "Shell integration is already configured. You can use 'ws open <workspace>' or 'git ws open <workspace>' to change directories automatically."
else
    echo "⚠️  Could not automatically add shell integration."
    echo "Please manually add the following lines to your shell profile:"
    echo
    echo "source \"$SHELL_INTEGRATION_FILE\""
    echo "source \"$GIT_SHELL_INTEGRATION_FILE\""
    echo
fi

echo "Run 'ws help' or 'git ws help' to see available commands."
