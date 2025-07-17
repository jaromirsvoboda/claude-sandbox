#!/bin/bash

# Usage: ./run-claude.sh /path/to/project [project-name] [--fresh]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name] [--fresh]"
    echo "Example: $0 /c/Projects/piper piper"
    echo "         $0 /c/Projects/piper piper --fresh"
    echo "Note: Resumes previous session by default if .claude directory exists"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"
FRESH_FLAG="$3"

# Check if Docker image exists, build if not
if ! docker image inspect claude-sandbox-claude >/dev/null 2>&1; then
    echo "Docker image not found. Building claude-sandbox-claude..."
    docker build -t claude-sandbox-claude .
fi

echo "Starting Claude sandbox for: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

# Check if .claude directory exists for session resumption
CLAUDE_CMD="claude"
if [ "$FRESH_FLAG" != "--fresh" ] && [ -d "$PROJECT_PATH/.claude" ]; then
    CLAUDE_CMD="claude --resume"
    echo "Resuming previous Claude session..."
else
    echo "Starting fresh Claude session..."
fi

docker run -it --rm \
    --name "claude-$PROJECT_NAME" \
    -v "$PROJECT_PATH:/workspace" \
    -v claude-config:/home/developer/.config \
    -p 3001:3000 \
    -p 8081:8080 \
    -p 5001:5000 \
    claude-sandbox-claude \
    bash -c "$CLAUDE_CMD"
