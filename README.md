# Claude Code Sandbox

Centralized Docker setup for running Claude Code safely in isolation while working on any project.

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
# Auto-builds image if needed
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# Resume previous session (if .claude directory exists)
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Resume

# With custom project name
.\run-claude.ps1 -ProjectPath "C:\Projects\my-app" -ProjectName "my-app"

# With custom ports
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Port1 3001 -Port2 8081 -Port3 5001

# No ports version
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper"

# No ports version with resume
.\run-claude-no-ports.ps1 -ProjectPath "C:\Projects\piper" -Resume
```

**Bash (Linux/WSL/Git Bash):**
```bash
# Auto-builds image if needed
./run-claude.sh /mnt/c/Projects/piper

# Resume previous session (if .claude directory exists)
./run-claude.sh /mnt/c/Projects/piper piper --resume

# With custom project name
./run-claude.sh /mnt/c/Projects/my-app my-app

# No ports version (avoids WSL port conflicts)
./run-claude-no-ports.sh /mnt/c/Projects/piper

# No ports version with resume
./run-claude-no-ports.sh /mnt/c/Projects/piper piper --resume

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

- **Auto-resume** if a `.claude` directory exists in your project
- **Manual resume** with the `-Resume` flag (PowerShell) or `--resume` flag (Bash)

```powershell
# First run - starts fresh
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# Subsequent runs - automatically resumes from previous session
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"
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
