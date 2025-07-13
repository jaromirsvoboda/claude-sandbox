# Claude Code Sandbox

Centralized Docker setup for running Claude Code safely in isolation while working on any project.

## Setup

1. Build the container (one time):

```powershell
cd c:\Projects\claude-sandbox
docker-compose build
```

## Usage

### Simple CLI approach (Recommended)

```powershell
# Basic usage
.\run-claude.ps1 -ProjectPath "C:\Projects\piper"

# With custom project name
.\run-claude.ps1 -ProjectPath "C:\Projects\my-app" -ProjectName "my-app"

# With custom ports
.\run-claude.ps1 -ProjectPath "C:\Projects\piper" -Port1 3001 -Port2 8081 -Port3 5001
```

### Old Docker Compose method (still works)

```powershell
cd c:\Projects\claude-sandbox
$env:PROJECT_PATH="C:/Projects/your-project"
$env:PROJECT_NAME="your-project"
docker-compose up -d
docker-compose exec claude claude
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
