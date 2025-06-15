#!/bin/bash

# Simple test script to verify tab completion works

echo "Testing ws tab completion..."

# Source the completion script
source ./ws-completion.bash

# Create a test workspace directory structure
mkdir -p test-workspaces/{feature1,feature2,bugfix}

# Test the completion function directly
echo "Testing completion for 'ws open ':"
COMP_WORDS=("ws" "open" "")
COMP_CWORD=2
_ws_completion
echo "Completions: ${COMPREPLY[@]}"

echo
echo "Testing completion for 'ws ':"
COMP_WORDS=("ws" "")
COMP_CWORD=1
_ws_completion
echo "Completions: ${COMPREPLY[@]}"

# Clean up
rm -rf test-workspaces

echo
echo "Tab completion test completed!"
echo "To test interactively:"
echo "1. Run: source ./ws-completion.bash"
echo "2. Type: ws <TAB>"
echo "3. Type: ws open <TAB>"
