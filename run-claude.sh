#!/bin/bash

# Usage: ./run-claude.sh /path/to/project [project-name] [--resume] [--forward-ports]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [project-name] [--resume] [--forward-ports]"
    echo "Example: $0 /c/Projects/piper piper"
    echo "         $0 /c/Projects/piper piper --resume"
    echo "         $0 /c/Projects/piper piper --forward-ports"
    echo "         $0 /c/Projects/piper --resume --forward-ports"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"

# Parse all remaining arguments for flags
RESUME_FLAG=""
FORWARD_PORTS=false
shift 2 2>/dev/null || shift 1  # Remove first two args, or just first if only one provided

for arg in "$@"; do
    case $arg in
        --resume)
            RESUME_FLAG="--resume"
            ;;
        --forward-ports)
            FORWARD_PORTS=true
            ;;
        --*)
            echo "Unknown flag: $arg" >&2
            exit 1
            ;;
        *)
            # If no project name was provided and this isn't a flag, treat as project name
            if [[ "$PROJECT_NAME" == "$(basename "$PROJECT_PATH")" ]] && [[ ! "$arg" == "--"* ]]; then
                PROJECT_NAME="$arg"
            fi
            ;;
    esac
done

# Smart auto-build logic: Check if image needs rebuilding
NEEDS_REBUILD=false

if ! docker image inspect claude-sandbox-claude >/dev/null 2>&1; then
    echo "Docker image not found. Building claude-sandbox-claude..."
    NEEDS_REBUILD=true
else
    # Files that affect the Docker build
    # Dynamically find files that affect the Docker build
    BUILD_FILES=("Dockerfile")  # Always include Dockerfile

    # Add files referenced in COPY commands in Dockerfile
    if [ -f "Dockerfile" ]; then
        while IFS= read -r line; do
            # Extract source file from COPY commands, handling --flags
            if [[ $line =~ ^[[:space:]]*COPY[[:space:]] ]]; then
                # Remove COPY and any leading whitespace
                cleaned_line=$(echo "$line" | sed 's/^[[:space:]]*COPY[[:space:]]*//')
                # Remove any --flags (anything starting with --)
                cleaned_line=$(echo "$cleaned_line" | sed 's/--[^[:space:]]*[[:space:]]*//')
                # Extract first word (source file)
                sourceFile=$(echo "$cleaned_line" | awk '{print $1}')
                if [ -n "$sourceFile" ]; then
                    BUILD_FILES+=("$sourceFile")
                fi
            fi
        done < "Dockerfile"
    fi

    # Remove duplicates and ensure files exist
    BUILD_FILES_FILTERED=()
    for file in "${BUILD_FILES[@]}"; do
        if [ -f "$file" ]; then
            # Check if already in filtered list
            inList=false
            for existing in "${BUILD_FILES_FILTERED[@]}"; do
                if [ "$existing" = "$file" ]; then
                    inList=true
                    break
                fi
            done
            if [ "$inList" = false ]; then
                BUILD_FILES_FILTERED+=("$file")
            fi
        fi
    done
    BUILD_FILES=("${BUILD_FILES_FILTERED[@]}")

    # Get image creation time
    IMAGE_CREATED=$(docker image inspect claude-sandbox-claude --format='{{.Created}}' 2>/dev/null)

    if [ -n "$IMAGE_CREATED" ]; then
        # Convert Docker timestamp to seconds since epoch
        IMAGE_CREATED_CLEAN=$(echo "$IMAGE_CREATED" | sed 's/\.[0-9]*Z$/Z/')
        IMAGE_CREATED_EPOCH=$(date -d "$IMAGE_CREATED_CLEAN" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$IMAGE_CREATED_CLEAN" +%s 2>/dev/null)

        if [ -n "$IMAGE_CREATED_EPOCH" ]; then
            # Check if any build file is newer than the image
            for file in "${BUILD_FILES[@]}"; do
                if [ -f "$file" ]; then
                    FILE_MODIFIED=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
                    if [ -n "$FILE_MODIFIED" ] && [ "$FILE_MODIFIED" -gt "$IMAGE_CREATED_EPOCH" ]; then
                        echo "$file modified since last build. Rebuilding claude-sandbox-claude..."
                        NEEDS_REBUILD=true
                        break
                    fi
                fi
            done
        else
            echo "Could not parse image timestamp. Rebuilding to be safe..."
            NEEDS_REBUILD=true
        fi
    else
        echo "Could not get image creation time. Rebuilding to be safe..."
        NEEDS_REBUILD=true
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

# Check if .claude directory exists for session resumption
CLAUDE_CMD="claude"
if [ "$RESUME_FLAG" = "--resume" ] || [ -d "$PROJECT_PATH/.claude" ]; then
    CLAUDE_CMD="claude --resume || claude"
    echo "Attempting to resume previous Claude session (will start fresh if no conversations found)..."
fi

# Startup command that includes global setup
STARTUP_CMD="source /home/developer/.claude-startup.sh 2>/dev/null || true; $CLAUDE_CMD"

# Generate consistent container name for volume persistence
CONTAINER_NAME="claude-$PROJECT_NAME"

# Build port arguments conditionally
PORT_ARGS=""
if [ "$FORWARD_PORTS" = true ]; then
    PORT_ARGS="-p 3001:3000 -p 8081:8080 -p 5001:5000"
    echo "Port forwarding enabled: 3001→3000, 8081→8080, 5001→5000"
fi

docker run -it --rm \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_PATH:/workspace" \
    -v claude-config:/home/developer/.config \
    -v claude-npm-global:/usr/local/lib/node_modules \
    $PORT_ARGS \
    claude-sandbox-claude \
    bash -c "$STARTUP_CMD"
