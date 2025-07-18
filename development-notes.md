# Claude Sandbox Development Notes

This document contains development context, decisions, and technical details about the Claude Code sandbox scripts.

## Overview

This repository provides centralized Docker scripts for running Claude Code safely in isolation while working on any project. It supports both PowerShell (Windows) and Bash (Linux/WSL/Git Bash) environments.

## Architecture

### Scripts Structure
- `run-claude.ps1` - PowerShell script with port forwarding
- `run-claude-no-ports.ps1` - PowerShell script without ports (WSL-friendly)
- `run-claude.sh` - Bash script with port forwarding
- `run-claude-no-ports.sh` - Bash script without ports (WSL-friendly)
- `Dockerfile` - Container definition
- `docker-compose.yml` - Legacy compose setup (still works)

### Container Setup
- **Base**: `debian:bullseye-slim`
- **User**: `developer` (non-root)
- **Working directory**: `/workspace`
- **Claude Code**: Installed via npm globally

## Storage Architecture

This is one of the most important architectural decisions in the setup. Understanding the two distinct storage locations is crucial for proper usage and troubleshooting.

### Authentication & Conversations
- **Location**: Docker volume `claude-config:/home/developer`
- **Contents**:
  - Authentication tokens (`.claude/.credentials.json`)
  - Conversation history (`.claude/projects/-workspace/*.jsonl`)
  - Shell snapshots, todos, and other Claude data
- **Persistence**: Machine-specific (tied to Docker volume)
- **Sharing**: Not shareable across machines by design

**Why Docker Volume?**
- **Performance**: Docker volumes are optimized for container I/O
- **Security**: Isolated from host filesystem, harder to accidentally expose
- **Consistency**: Same location regardless of project or host OS
- **Claude Code expectation**: Matches where Claude Code naturally stores data

### Project Settings
- **Location**: Project directory `.claude/` folder
- **Contents**: `settings.local.json` (permissions, etc.)
- **Persistence**: Project-specific, travels with the project
- **Sharing**: Can be committed to git (but usually shouldn't be)

**Why Project Directory?**
- **Project-specific**: Settings like allowed tools are per-project
- **Version control**: Can be tracked with project if desired
- **Portability**: Travels with project code
- **Isolation**: Different projects can have different Claude settings

### The Two-Location Strategy Reasoning

**Initial Confusion**: We initially thought everything was in the project `.claude/` directory, but discovered conversations were missing after changing machines.

**Investigation Revealed**:
1. Project `.claude/` only had `settings.local.json` (151 bytes)
2. Docker volume `claude-config` contained the actual conversation files (multiple `.jsonl` files)

**Why This Separation Makes Sense**:
1. **Privacy**: Conversations often contain sensitive data that shouldn't be in git
2. **Size**: Conversation history can be large (each conversation is a separate .jsonl file)
3. **Performance**: Docker volumes are faster than mounted directories for frequent R/W
4. **Claude Code Architecture**: The tool naturally separates these concerns

**Alternative Considered**: Store everything in project directory
```bash
# This would make conversations project-specific and shareable
-v "$PROJECT_PATH/.claude:/home/developer/.claude"
```

**Why We Rejected This**:
- Privacy: Conversations contain sensitive information
- Git pollution: Large conversation files would bloat repositories
- Performance: Mounted directories slower than Docker volumes
- Security: Easier to accidentally commit sensitive data

## Key Technical Decisions

### 1. Conversation Storage Location
**Decision**: Keep conversations in Docker volume (machine-specific)
**Alternatives considered**:
- Store in project directory for cross-machine sharing
- Mount conversations to project: `-v "$PROJECT_PATH/.claude-conversations:/home/developer/.claude/projects"`

**Rationale**:
- **Privacy**: Conversations often contain sensitive information
- **Performance**: Docker volumes are faster than mounted directories
- **Git hygiene**: Keeps repositories clean
- **Flexibility**: Can selectively export conversations when needed

### 2. Authentication Persistence
**Problem**: Users had to re-authenticate every session
**Solution**: Mount entire home directory instead of just config
```bash
# Before (didn't work)
-v "claude-config:/home/developer/.config"

# After (works)
-v "claude-config:/home/developer"
```

### 3. Session Resumption Strategy
**Default behavior**: Auto-resume most recent conversation, fallback to fresh
**Implementation**: `claude --continue || claude`

**Three modes**:
1. **Default**: Resume most recent conversation automatically
2. **Interactive selection**: Use `--resume` flag for conversation menu
3. **Fresh start**: Explicitly start new conversation

### 4. Line Endings Fix
**Problem**: Windows CRLF line endings prevented bash script execution
**Solution**: Use `dos2unix` to convert line endings
```bash
wsl dos2unix run-claude-no-ports.sh run-claude.sh
```

### 5. Argument Parsing Enhancement
**Problem**: Flags in position 2 were treated as project names
**Solution**: Detect flags starting with `--` and adjust parsing
```bash
# Handle case where flag is in position 2 (no project name specified)
if [[ "$2" == "--"* ]]; then
    PROJECT_NAME="$(basename "$PROJECT_PATH")"
    FLAG="$2"
fi
```

## Script Parameters

### PowerShell Scripts
```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,              # Required: Path to project
    [string]$ProjectName,              # Optional: Container name (defaults to folder name)
    [int]$Port1 = 3000,               # Optional: First port mapping (run-claude.ps1 only)
    [int]$Port2 = 8080,               # Optional: Second port mapping (run-claude.ps1 only)
    [int]$Port3 = 5000,               # Optional: Third port mapping (run-claude.ps1 only)
    [switch]$Fresh,                   # Optional: Start fresh session
    [switch]$SelectConversation       # Optional: Interactive conversation selection
)
```

### Bash Scripts
```bash
PROJECT_PATH="$1"                     # Required: Path to project
PROJECT_NAME="${2:-$(basename "$PROJECT_PATH")}"  # Optional: Container name
FLAG="$3"                            # Optional: --fresh or --select-conversation
```

## Usage Patterns

### Quick Start (Most Common)
```bash
# Auto-resume most recent conversation
./run-claude-no-ports.sh /mnt/c/Projects/piper
```

### Interactive Conversation Selection
```bash
# Choose from available conversations
./run-claude-no-ports.sh /mnt/c/Projects/piper --select-conversation
```

### Fresh Session
```bash
# Start completely fresh
./run-claude-no-ports.sh /mnt/c/Projects/piper --fresh
```

## Container Behavior

### Volume Mounts
1. `"$PROJECT_PATH:/workspace"` - Project files (read/write)
2. `"claude-config:/home/developer"` - Authentication & conversations (persistent)

### Port Forwarding (non-no-ports versions)
- `3000` → `Port1` (default 3000)
- `8080` → `Port2` (default 8080)
- `5000` → `Port3` (default 5000)

### Container Naming
- With ports: `claude-$PROJECT_NAME`
- No ports: `claude-$PROJECT_NAME-noports`

## Troubleshooting

### Authentication Issues
1. **Check volume exists**: `docker volume ls | findstr claude-config`
2. **Check volume contents**: `docker run --rm -v claude-config:/config busybox ls -la /config`
3. **Reset if needed**: `docker volume rm claude-config`

### WSL Line Ending Issues
```bash
wsl dos2unix run-claude-no-ports.sh run-claude.sh
```

### Syntax Errors in Bash Scripts
- Usually caused by Windows CRLF line endings
- Use `dos2unix` to fix
- Check syntax: `wsl bash -n script.sh`

### Port Conflicts
- Use no-ports versions for WSL
- Or specify different ports in PowerShell scripts

## Claude Code Flags Reference

Based on `claude --help` output:

### Session Management
- `-c, --continue` - Continue the most recent conversation
- `-r, --resume [sessionId]` - Resume a conversation (interactive if no ID)
- `--session-id <uuid>` - Use specific session ID

### Useful Flags
- `--fresh` - Not a real Claude flag, our script convention
- `--select-conversation` - Not a real Claude flag, our script convention
- `-d, --debug` - Enable debug mode
- `--dangerously-skip-permissions` - Bypass permission checks

## File Structure

```
claude-sandbox/
├── run-claude.ps1              # PowerShell with ports
├── run-claude-no-ports.ps1     # PowerShell without ports
├── run-claude.sh               # Bash with ports
├── run-claude-no-ports.sh      # Bash without ports
├── Dockerfile                  # Container definition
├── docker-compose.yml          # Legacy setup
├── README.md                   # User documentation
├── DEVELOPMENT_NOTES.md        # This file
└── .claude/                    # Local settings (if any)
```

## Future Considerations

### Conversation Sharing Across Machines
If needed in the future, could implement:
```bash
# Add conversation sharing mount
-v "$PROJECT_PATH/.claude-conversations:/home/developer/.claude/projects"
```

**Pros**: Cross-machine conversation sharing
**Cons**: Privacy concerns, git bloat, performance impact

### Project-Specific Authentication
Could isolate authentication per project:
```bash
-v "$PROJECT_PATH/.claude-auth:/home/developer/.claude"
```

### Export/Import Functionality
Could add scripts to export/import specific conversations for sharing.

## Version History

### v1.0 - Initial Setup
- Basic Docker container with Claude Code
- Simple run scripts

### v1.1 - Authentication Fix
- Fixed persistent authentication by mounting full home directory
- Resolved re-authentication issues

### v1.2 - Session Management
- Added resume functionality with fallback
- Three modes: auto-resume, select, fresh

### v1.3 - Argument Parsing
- Fixed flag detection in bash scripts
- Improved usage examples

### v1.4 - Line Endings
- Fixed WSL compatibility with dos2unix
- Resolved bash syntax errors

## Development Environment

- **OS**: Windows with WSL2
- **Docker**: Docker Desktop with WSL integration
- **Shell**: PowerShell 5.1 and Bash (WSL)
- **Paths**:
  - WSL: `/mnt/c/Projects/`
  - Git Bash: `/c/Projects/`
  - Windows: `C:\Projects\`

## Contact & Continuation

This setup was developed through iterative problem-solving with Claude Code. Key areas that required multiple iterations:
1. Authentication persistence
2. Session resumption strategy
3. Cross-platform compatibility
4. Argument parsing edge cases

When continuing development on another machine, ensure:
1. Docker Desktop with WSL integration enabled
2. Proper line endings on bash scripts (`dos2unix`)
3. Understanding of the two storage locations (volume vs project)
