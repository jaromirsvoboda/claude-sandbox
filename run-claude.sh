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
            IMAGE_CREATED_EPOCH=$(date -d "$IMAGE_CREATED" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${IMAGE_CREATED%.*}" +%s 2>/dev/null)

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
    docker build -t claude-sandbox-claude .
    if [ $? -ne 0 ]; then
        echo "Docker build failed!" >&2
        exit 1
    fi
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
