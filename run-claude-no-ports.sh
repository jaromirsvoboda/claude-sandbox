#!/bin/bash

# Usage: ./run-claude-no-ports.sh /path/to/project [project-name] [--fresh|--select-conversation]
# This version doesn't expose any ports to avoid Windows/WSL port conflicts

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name] [--fresh|--select-conversation]"
    echo "       $0 <project-path> [--fresh|--select-conversation]"
    echo "Example: $0 /mnt/c/Projects/piper"
    echo "         $0 /mnt/c/Projects/piper --fresh"
    echo "         $0 /mnt/c/Projects/piper --select-conversation"
    echo "         $0 /mnt/c/Projects/piper my-project --fresh"
    echo "Note: Resumes most recent conversation by default if .claude directory exists"
    echo "Note: No ports exposed - use for file editing only"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"
FLAG="$3"

# Handle case where flag is in position 2 (no project name specified)
if [[ "$2" == "--"* ]]; then
    PROJECT_NAME="$(basename "$PROJECT_PATH")"
    FLAG="$2"
fi

# Check if Docker image exists, build if not
if ! docker image inspect claude-sandbox-claude >/dev/null 2>&1; then
    echo "Docker image not found. Building claude-sandbox-claude..."
    docker build -t claude-sandbox-claude .
fi

echo "Starting Claude sandbox for: $PROJECT_NAME (no ports)"
echo "Project path: $PROJECT_PATH"

# Check if .claude directory exists for session resumption
CLAUDE_CMD="claude"
if [ "$FLAG" = "--fresh" ]; then
    echo "Starting fresh Claude session..."
elif [ "$FLAG" = "--select-conversation" ] && [ -d "$PROJECT_PATH/.claude" ]; then
    CLAUDE_CMD="claude --resume"
    echo "Opening conversation selection menu..."
elif [ "$FLAG" != "--fresh" ] && [ -d "$PROJECT_PATH/.claude" ]; then
    CLAUDE_CMD="claude --continue || claude"
    echo "Attempting to resume previous Claude session (will start fresh if no conversation found)..."
else
    echo "Starting fresh Claude session..."
fi

docker run -it --rm \
    --name "claude-$PROJECT_NAME-noports" \
    -v "$PROJECT_PATH:/workspace" \
    -v claude-config:/home/developer \
    -v claude-npm-global:/usr/local/lib/node_modules \
    claude-sandbox-claude \
    bash -c "$CLAUDE_CMD"
