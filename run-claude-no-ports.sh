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

# Smart auto-build logic: Check if image needs rebuilding
NEEDS_REBUILD=false

if ! docker image inspect claude-sandbox-claude >/dev/null 2>&1; then
    echo "Docker image not found. Building claude-sandbox-claude..."
    NEEDS_REBUILD=true
else
    # Check if Dockerfile is newer than the existing image
    if [ -f "Dockerfile" ]; then
        # Get Dockerfile modification time (seconds since epoch)
        DOCKERFILE_MODIFIED=$(stat -c %Y Dockerfile 2>/dev/null || stat -f %m Dockerfile 2>/dev/null)

        # Get image creation time
        IMAGE_CREATED=$(docker image inspect claude-sandbox-claude --format='{{.Created}}' 2>/dev/null)

        if [ -n "$IMAGE_CREATED" ] && [ -n "$DOCKERFILE_MODIFIED" ]; then
            # Convert Docker timestamp to seconds since epoch
            # Remove microseconds from timestamp for better compatibility
            IMAGE_CREATED_CLEAN=$(echo "$IMAGE_CREATED" | sed 's/\.[0-9]*Z$/Z/')
            IMAGE_CREATED_EPOCH=$(date -d "$IMAGE_CREATED_CLEAN" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$IMAGE_CREATED_CLEAN" +%s 2>/dev/null)

            if [ -n "$IMAGE_CREATED_EPOCH" ] && [ "$DOCKERFILE_MODIFIED" -gt "$IMAGE_CREATED_EPOCH" ]; then
                echo "Dockerfile modified since last build. Rebuilding claude-sandbox-claude..."
                NEEDS_REBUILD=true
            fi
        else
            echo "Could not compare timestamps. Rebuilding to be safe..."
            NEEDS_REBUILD=true
        fi
    fi
fi

if [ "$NEEDS_REBUILD" = true ]; then
    # Change to script directory for Docker build context
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"

    docker build -t claude-sandbox-claude .
    if [ $? -ne 0 ]; then
        echo "Docker build failed!" >&2
        exit 1
    fi
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

# Startup command that includes global setup
STARTUP_CMD="source /home/developer/.claude-startup.sh 2>/dev/null || true; $CLAUDE_CMD"

docker run -it --rm \
    --name "claude-$PROJECT_NAME-noports" \
    -v "$PROJECT_PATH:/workspace" \
    -v claude-config:/home/developer \
    -v claude-npm-global:/usr/local/lib/node_modules \
    claude-sandbox-claude \
    bash -c "$STARTUP_CMD"
