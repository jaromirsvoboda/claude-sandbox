#!/bin/bash

# Claude Sandbox launcher
# Usage: ./run-claude.sh <project-path> [project-name] [flags...]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name] [flags...]"
    echo ""
    echo "Examples:"
    echo "  $0 /c/Projects/piper"
    echo "  $0 /c/Projects/piper --forward-ports"
    echo "  $0 /c/Projects/piper --fresh"
    echo "  $0 /c/Projects/piper --resume"
    echo "  $0 /c/Projects/piper --instance feature-auth"
    echo "  $0 /c/Projects/piper my-project --resume --instance alpha"
    echo ""
    echo "Flags:"
    echo "  --forward-ports         Expose ports 3001:3000, 8081:8080, 5001:5000"
    echo "  --fresh                 Start fresh session (ignore existing .claude)"
    echo "  --resume                Force resume mode (default if .claude exists)"
    echo "  --select-conversation   Interactive conversation selection"
    echo "  --instance NAME         Use named instance (separate container/volumes)"
    echo "                          Default instance: 'default'"
    echo ""
    echo "Multi-instance support:"
    echo "  Each instance has isolated conversations and authentication"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"

# Default settings (secure defaults - no ports exposed)
FORWARD_PORTS=false
SESSION_MODE="auto"  # auto, fresh, resume, select
INSTANCE_NAME="default"

# Parse arguments for flags
shift 2 2>/dev/null || shift 1
while [ $# -gt 0 ]; do
    case $1 in
        --forward-ports)
            FORWARD_PORTS=true
            shift
            ;;
        --fresh)
            SESSION_MODE="fresh"
            shift
            ;;
        --resume)
            SESSION_MODE="resume"
            shift
            ;;
        --select-conversation)
            SESSION_MODE="select"
            shift
            ;;
        --instance)
            if [ -n "$2" ]; then
                INSTANCE_NAME="$2"
                shift 2
            else
                echo "Error: --instance requires a name" >&2
                exit 1
            fi
            ;;
        --*)
            echo "Unknown flag: $1" >&2
            exit 1
            ;;
        *)
            # If we reach here, it might be a project name we missed
            if [ "$PROJECT_NAME" = "$(basename "$PROJECT_PATH")" ]; then
                PROJECT_NAME="$1"
            else
                echo "Unexpected argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Display version and instance information
if [ -f "VERSION" ]; then
    source VERSION
    PORT_INFO=""
    if [ "$FORWARD_PORTS" = true ]; then
        PORT_INFO=" (ports: 3001,8081,5001)"
    fi

    if [ "$INSTANCE_NAME" = "default" ]; then
        echo "🚀 Claude Sandbox ${CLAUDE_SANDBOX_VERSION}${PORT_INFO} - Starting..."
    else
        echo "🚀 Claude Sandbox ${CLAUDE_SANDBOX_VERSION} [$INSTANCE_NAME]${PORT_INFO} - Starting..."
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
if [ "$INSTANCE_NAME" != "default" ]; then
    echo "Instance: $INSTANCE_NAME"
fi

# Determine Claude command based on session mode
CLAUDE_CMD="claude"
case $SESSION_MODE in
    fresh)
        CLAUDE_CMD="claude"
        echo "Starting fresh Claude session..."
        ;;
    resume)
        CLAUDE_CMD="claude --resume"
        echo "Resuming previous Claude session..."
        ;;
    select)
        CLAUDE_CMD="claude --select-conversation"
        echo "Starting Claude with conversation selection..."
        ;;
    auto)
        # Auto mode: resume if .claude exists, otherwise fresh
        if [ -d "$PROJECT_PATH/.claude" ]; then
            CLAUDE_CMD="claude --continue || claude"
            echo "Attempting to resume previous Claude session (will start fresh if no conversation found)..."
        else
            echo "Starting fresh Claude session..."
        fi
        ;;
esac

# Startup command that includes global setup
STARTUP_CMD="source /home/developer/.claude-startup.sh 2>/dev/null || true; $CLAUDE_CMD"

# Generate instance-specific container and volume names
if [ "$INSTANCE_NAME" = "default" ]; then
    if [ "$FORWARD_PORTS" = true ]; then
        CONTAINER_NAME="claude-$PROJECT_NAME"
    else
        CONTAINER_NAME="claude-$PROJECT_NAME-noports"
    fi
    CONFIG_VOLUME="claude-config"
else
    if [ "$FORWARD_PORTS" = true ]; then
        CONTAINER_NAME="claude-$PROJECT_NAME-$INSTANCE_NAME"
    else
        CONTAINER_NAME="claude-$PROJECT_NAME-noports-$INSTANCE_NAME"
    fi
    CONFIG_VOLUME="claude-config-$INSTANCE_NAME"
fi

echo "Container: $CONTAINER_NAME"
echo "Config volume: $CONFIG_VOLUME"

# Show port information before the pause
if [ "$FORWARD_PORTS" = true ]; then
    echo "Port forwarding: 3001→3000, 8081→8080, 5001→5000"
else
    echo "No ports exposed (secure mode)"
fi

# Check if container already exists

# If container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
    if [ "$CONTAINER_STATUS" = "running" ]; then
        echo "Container '$CONTAINER_NAME' is already running. Connecting to existing session..."
        docker exec -it "$CONTAINER_NAME" bash -c "$STARTUP_CMD"
        exit 0
    else
        echo "Container '$CONTAINER_NAME' is stopped. Removing and recreating to ensure a working session..."
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1
        # Continue to docker run below (preserves config volume)
    fi
fi

echo ""
echo "Press Enter to continue to Claude..."
read -r

# Build Docker command
DOCKER_CMD="docker run -it --name \"$CONTAINER_NAME\" -v \"$PROJECT_PATH:/workspace\" -v \"$CONFIG_VOLUME:/home/developer/.config\" -v claude-npm-global:/usr/local/lib/node_modules"

# Add port forwarding if requested
if [ "$FORWARD_PORTS" = true ]; then
    DOCKER_CMD="$DOCKER_CMD -p 3001:3000 -p 8081:8080 -p 5001:5000"
else
    # No ports to add
    :
fi

# Complete the command
DOCKER_CMD="$DOCKER_CMD claude-sandbox-claude bash -c \"$STARTUP_CMD\""

# Execute the Docker command
eval $DOCKER_CMD
