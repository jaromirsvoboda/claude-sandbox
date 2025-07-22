# Claude Code Sandbox

Centralized Docker setup for running Claude Code safely in isolation while working on any project.

**Current Version:** See `VERSION` file or run any script to see version information.

## Setup

1. **The scripts will auto-build the container when needed**, but you can build manually:

```powershell
cd c:\Projects\claude-sandbox
docker-compose build
```

## Usage

**Secure by default:** The scripts don't expose ports unless explicitly requested with `--forward-ports` flag.

**PowerShell (Windows):**
```powershell
# Basic usage (no ports exposed - secure default)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# With port forwarding for web apps
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -ForwardPorts

# Fresh session (ignore existing .claude directory)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Fresh

# Multi-instance support
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "feature-auth"
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "alpha" -ForwardPorts

# Custom ports (only with ForwardPorts)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -ForwardPorts -Port1 3001 -Port2 8081 -Port3 5001
```

**Bash (Linux/WSL/Git Bash):**
```bash
# Basic usage (no ports exposed - secure default)
./run-claude.sh /mnt/c/Projects/piper

# With port forwarding for web apps
./run-claude.sh /mnt/c/Projects/piper --forward-ports

# Fresh session
./run-claude.sh /mnt/c/Projects/piper --fresh

# Multi-instance support
./run-claude.sh /mnt/c/Projects/piper --instance feature-auth
./run-claude.sh /mnt/c/Projects/piper --instance alpha --forward-ports
```

# With custom project name
.\run-claude.ps1 -ProjectPath "C:\Projects\my-app" -ProjectName "my-app"

# Multi-instance support - run multiple Claude instances on same project
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "feature-auth"
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "alpha"

# With custom ports
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Port1 3001 -Port2 8081 -Port3 5001

# No ports version (resumes most recent conversation automatically)
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper"

# No ports version with fresh start
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper" -Fresh

# No ports version with named instance
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper" -Instance "beta"
```

**Bash (Linux/WSL/Git Bash):**
```bash
# Auto-builds image if needed (resumes most recent conversation automatically)
./run-claude.sh /mnt/c/Projects/piper

# With resume flag
./run-claude.sh /mnt/c/Projects/piper --resume

# Multi-instance support - run multiple Claude instances on same project
./run-claude.sh /mnt/c/Projects/piper --instance feature-auth
./run-claude.sh /mnt/c/Projects/piper --instance alpha
./run-claude.sh /mnt/c/Projects/piper piper --resume --instance beta

# No ports version
./run-claude-no-ports.sh /mnt/c/Projects/piper

# No ports with fresh start
./run-claude-no-ports.sh /mnt/c/Projects/piper --fresh

# No ports with named instance
./run-claude-no-ports.sh /mnt/c/Projects/piper --instance feature-ui

# Start fresh session (ignore existing .claude directory)
./run-claude.sh /mnt/c/Projects/piper piper --fresh

# Select from available conversations interactively
./run-claude.sh /mnt/c/Projects/piper piper --select-conversation

# With custom project name
./run-claude.sh /mnt/c/Projects/my-app my-app

# No ports version (resumes most recent conversation automatically)
./run-claude-no-ports.sh /mnt/c/Projects/piper

# No ports version with fresh start
./run-claude-no-ports.sh /mnt/c/Projects/piper piper --fresh

# No ports version with conversation selection
./run-claude-no-ports.sh /mnt/c/Projects/piper piper --select-conversation

# Note: For WSL, use /mnt/c/ path format
# For Git Bash, use /c/ path format
```

### Old Docker Compose method (still works)

```powershell
cd c:\Projects\claude-sandbox
$env:PROJECT_PATH="C:/Projects/your-project"
$env:PROJECT_NAME="your-project"
docker-compose up -d
docker-compose exec claude claude
```

## Session Resumption

Claude Code automatically saves your conversation context in a `.claude` directory in your project. The scripts will:

- **Auto-resume by default** if a `.claude` directory exists and contains conversation history
- **Fall back to fresh start** if `.claude` exists but has no conversations to resume
- **Start fresh** with the `-Fresh` flag (PowerShell) or `--fresh` flag (Bash)

```powershell
# First run - starts fresh
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# Subsequent runs - attempts to resume, falls back to fresh if no conversations found
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# Force fresh start (ignore existing session completely)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Fresh
```

To start fresh (ignore existing session):
```powershell
# Remove the .claude directory first
Remove-Item "C:\Projects\piper\.claude" -Recurse -Force
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"
```

## Managing the Container

```powershell
# Stop any running containers
docker ps -a --filter "name=claude-*" --format "table {{.Names}}\t{{.Status}}"

# Stop specific container
docker stop claude-piper

# Remove specific container
docker rm claude-piper

# View logs
docker logs claude-piper
```

## Multiple Projects

Work on multiple projects simultaneously with different ports:

```powershell
# Project 1
.\run-claude.ps1 -ProjectPath "C:\Projects\app1" -ProjectName "app1" -Port1 3000

# Project 2 (different ports)
.\run-claude.ps1 -ProjectPath "C:\Projects\app2" -ProjectName "app2" -Port1 3001
```

## Multi-Instance Support

You can run multiple Claude instances on the same project simultaneously using named instances:

**PowerShell:**

```powershell
# Default instance
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# Named instances for parallel development
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "feature-auth"
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "refactor"
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Instance "experiment"
```

**Bash:**

```bash
# Default instance
./run-claude.sh /mnt/c/Projects/piper

# Named instances for parallel development
./run-claude.sh /mnt/c/Projects/piper --instance feature-auth
./run-claude.sh /mnt/c/Projects/piper --instance refactor
./run-claude.sh /mnt/c/Projects/piper --instance experiment
```

Each instance maintains its own:
- Isolated conversation history
- Separate Docker container
- Independent configuration volume
- Unique container naming (`claude-PROJECT-INSTANCE`)

This allows you to work on different features, experiments, or approaches simultaneously without conversations interfering with each other.

## Troubleshooting

### Container Name Conflicts
If you get "container name already in use" errors:

**The scripts now handle this automatically** by detecting existing containers:

- **Running container**: Automatically connects to your existing session
- **Stopped container**: Automatically starts it and connects to your session

**Manual cleanup (if needed):**
```bash
# List all Claude containers
docker ps -a --filter "name=claude-*"

# Force remove specific container
docker rm -f claude-piper-noports

# Remove all stopped Claude containers
docker container prune --filter "label=claude-sandbox"
```

### Port conflicts
If you get "port not available" errors:

```powershell
# Check what's using the port
netstat -ano | findstr :3000

# Use different ports
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Port1 3002 -Port2 8082
```

### WSL Issues
- Ensure Docker Desktop WSL integration is enabled
- Use `/mnt/c/` path format in WSL
- Use `/c/` path format in Git Bash

**Port conflicts in WSL:** Use the no-ports version:
```bash
# No port forwarding (avoids WSL networking issues)
./run-claude-no-ports.sh /mnt/c/Projects/piper
```

### Authentication Issues

**Frequent re-authentication:** Claude Code should cache authentication in the `claude-config` Docker volume. If you're being asked to authenticate every time:

1. **Check if volume persists:**
   ```powershell
   docker volume ls | findstr claude-config
   ```

2. **Check if auth data is being saved:**
   ```powershell
   docker run --rm -v claude-config:/config busybox ls -la /config
   ```

3. **Reset authentication cache:**
   ```powershell
   docker volume rm claude-config
   ```

4. **Ensure consistent container naming:** The scripts use consistent names (`claude-<project>`) to maintain the same volume across runs.
