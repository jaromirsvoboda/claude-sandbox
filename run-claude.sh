#!/bin/bash

# Usage: ./run-claude.sh /path/to/project [project-name] [--resume]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name] [--resume]"
    echo "Example: $0 /c/Projects/piper piper"
    echo "         $0 /c/Projects/piper piper --resume"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"
RESUME_FLAG="$3"

# Handle case where flag is in position 2 (no project name specified)
if [[ "$2" == "--"* ]]; then
    PROJECT_NAME="$(basename "$PROJECT_PATH")"
    RESUME_FLAG="$2"
fi

# Check if Docker image exists, build if not
if ! docker image inspect claude-sandbox-claude >/dev/null 2>&1; then
    echo "Docker image not found. Building claude-sandbox-claude..."
    docker build -t claude-sandbox-claude .
fi

echo "Starting Claude sandbox for: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

# Check if .claude directory exists for session resumption
CLAUDE_CMD="claude"
if [ "$RESUME_FLAG" = "--resume" ] || [ -d "$PROJECT_PATH/.claude" ]; then
    CLAUDE_CMD="claude --resume"
    echo "Resuming previous Claude session..."
fi

docker run -it --rm \
    --name "claude-$PROJECT_NAME" \
    -v "$PROJECT_PATH:/workspace" \
    -v claude-config:/home/developer/.config \
    -v claude-npm-global:/usr/local/lib/node_modules \
    -p 3001:3000 \
    -p 8081:8080 \
    -p 5001:5000 \
    claude-sandbox-claude \
    bash -c "$CLAUDE_CMD"
