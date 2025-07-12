# Claude Code Sandbox

Centralized Docker setup for running Claude Code safely in isolation while working on any project.

## Setup

1. Build the container (one time):
```powershell
cd c:\Projects\claude-sandbox
docker-compose build
```

## Usage

### Method 1: Using .env file (Recommended)
```powershell
cd c:\Projects\claude-sandbox
cp .env.example .env
# Edit .env to set your project path and name
docker-compose up -d
docker-compose exec claude claude
```

### Method 2: Using PowerShell script
```powershell
c:\Projects\claude-sandbox\claude-start.ps1 -ProjectPath "C:/Projects/your-project"
```

### Method 3: Using environment variables
```powershell
cd c:\Projects\claude-sandbox
$env:PROJECT_PATH="C:/Projects/your-project"
$env:PROJECT_NAME="your-project"
docker-compose up -d
docker-compose exec claude claude
```

## Managing the Container

```powershell
# Stop the container
docker-compose stop

# Start it again (auth persists)
docker-compose start

# Remove container (keeps auth volume)
docker-compose down

# Remove everything including auth
docker-compose down -v

# View logs
docker-compose logs -f
```

## Multiple Projects

To work on multiple projects simultaneously, use different project names and ports:

```powershell
# Project 1
$env:PROJECT_PATH="C:/Projects/app1"
$env:PROJECT_NAME="app1"
$env:PORT1="3000"
docker-compose up -d

# Project 2 (in different terminal)
$env:PROJECT_PATH="C:/Projects/app2"
$env:PROJECT_NAME="app2"
$env:PORT1="3001"
docker-compose up -d
```
