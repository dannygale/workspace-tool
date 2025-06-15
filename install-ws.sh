#!/bin/bash

# Installation script for the ws workspace management tool

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"

echo "Installing workspace management tool..."

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy the main script
cp "$SCRIPT_DIR/ws" "$INSTALL_DIR/ws"
chmod +x "$INSTALL_DIR/ws"

echo "✓ Installed ws to $INSTALL_DIR/ws"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo
    echo "⚠️  $HOME/.local/bin is not in your PATH"
    echo "Add the following line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
fi

# Provide instructions for the shell function
echo
echo "To enable the 'ws open' command to change directories, add this function to your shell profile:"
echo
cat << 'EOF'
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
EOF

echo
echo "Installation complete! Run 'ws help' to see available commands."
