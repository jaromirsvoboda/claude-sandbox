#!/bin/bash

# Usage: ./run-claude.sh /path/to/project [project-name]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name]"
    echo "Example: $0 /c/Projects/piper piper"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"

echo "Starting Claude sandbox for: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

docker run -it --rm \
    --name "claude-$PROJECT_NAME" \
    -v "$PROJECT_PATH:/workspace" \
    -v claude-config:/home/developer/.config \
    -p 3000:3000 \
    -p 8080:8080 \
    -p 5000:5000 \
    claude-sandbox-claude \
    claude
