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

### Simple CLI approach (Recommended)

**PowerShell (Windows):**
```powershell
# Auto-builds image if needed (resumes most recent conversation automatically)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# Start fresh session (ignore existing .claude directory)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Fresh

# Select from available conversations interactively
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -SelectConversation

# With custom project name
.\run-claude.ps1 -ProjectPath "C:\Projects\my-app" -ProjectName "my-app"

# With custom ports
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Port1 3001 -Port2 8081 -Port3 5001

# No ports version (resumes most recent conversation automatically)
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper"

# No ports version with fresh start
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper" -Fresh

# No ports version with conversation selection
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper" -SelectConversation
```

**Bash (Linux/WSL/Git Bash):**
```bash
# Auto-builds image if needed (resumes most recent conversation automatically)
./run-claude.sh /mnt/c/Projects/piper

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

## Troubleshooting

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
