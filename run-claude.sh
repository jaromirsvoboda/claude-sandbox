#!/bin/bash

# Usage: ./run-claude.sh /path/to/project [project-name] [--resume] [--instance instance-name]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name] [--resume] [--instance instance-name]"
    echo "Example: $0 /c/Projects/piper piper"
    echo "         $0 /c/Projects/piper piper --resume"
    echo "         $0 /c/Projects/piper --instance feature-auth"
    echo "         $0 /c/Projects/piper piper --resume --instance alpha"
    echo ""
    echo "Multi-instance support:"
    echo "  --instance NAME    Use named instance (creates separate container/volumes)"
    echo "                     Default instance: 'default'"
    echo "                     Each instance has isolated conversations and auth"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"
RESUME_FLAG=""
INSTANCE_NAME="default"

# Parse arguments for flags
shift 2 2>/dev/null || shift 1
for arg in "$@"; do
    case $arg in
        --resume)
            RESUME_FLAG="--resume"
            ;;
        --instance)
            shift
            if [ -n "$1" ]; then
                INSTANCE_NAME="$1"
                shift
            else
                echo "Error: --instance requires a name" >&2
                exit 1
            fi
            ;;
        --*)
            echo "Unknown flag: $arg" >&2
            exit 1
            ;;
    esac
done

# Handle case where second argument is a flag (no project name specified)
if [[ "$2" == "--"* ]]; then
    PROJECT_NAME="$(basename "$PROJECT_PATH")"
    # Re-parse from position 2
    shift 1
    for arg in "$@"; do
        case $arg in
            --resume)
                RESUME_FLAG="--resume"
                ;;
            --instance)
                shift
                if [ -n "$1" ]; then
                    INSTANCE_NAME="$1"
                    shift
                else
                    echo "Error: --instance requires a name" >&2
                    exit 1
                fi
                ;;
        esac
    done
fi

# Display version and instance information
if [ -f "VERSION" ]; then
    source VERSION
    if [ "$INSTANCE_NAME" = "default" ]; then
        echo "🚀 Claude Sandbox ${CLAUDE_SANDBOX_VERSION} - Starting..."
    else
        echo "🚀 Claude Sandbox ${CLAUDE_SANDBOX_VERSION} [$INSTANCE_NAME] - Starting..."
    fi
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

echo "Starting Claude sandbox for: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

echo "Starting Claude sandbox for: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"
if [ "$INSTANCE_NAME" != "default" ]; then
    echo "Instance: $INSTANCE_NAME"
fi

# Check if .claude directory exists for session resumption
CLAUDE_CMD="claude"
if [ "$RESUME_FLAG" = "--resume" ] || [ -d "$PROJECT_PATH/.claude" ]; then
    CLAUDE_CMD="claude --resume"
    echo "Resuming previous Claude session..."
fi

# Startup command that includes global setup
STARTUP_CMD="source /home/developer/.claude-startup.sh 2>/dev/null || true; $CLAUDE_CMD"

# Generate instance-specific container and volume names
if [ "$INSTANCE_NAME" = "default" ]; then
    CONTAINER_NAME="claude-$PROJECT_NAME"
    CONFIG_VOLUME="claude-config"
else
    CONTAINER_NAME="claude-$PROJECT_NAME-$INSTANCE_NAME"
    CONFIG_VOLUME="claude-config-$INSTANCE_NAME"
fi

echo "Container: $CONTAINER_NAME"
echo "Config volume: $CONFIG_VOLUME"

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_PATH:/workspace" \
    -v "$CONFIG_VOLUME:/home/developer/.config" \
    -v claude-npm-global:/usr/local/lib/node_modules \
    -p 3001:3000 \
    -p 8081:8080 \
    -p 5001:5000 \
    claude-sandbox-claude \
    bash -c "$STARTUP_CMD"
