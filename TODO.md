# TODO List

This file tracks planned features and improvements for the Claude Sandbox project.

## High Priority

### Multi-Instance Support ✅
- **Goal**: Allow running multiple instances of Claude on the same repository
- **Implementation**: Manual container name handling (e.g., `--instance-name` or `--suffix` flag)
- **Benefits**: Multiple developers can work on same project simultaneously
- **Example**: `./run-claude.sh /path/to/project --instance dev1`
- **Status**: COMPLETED
  - ✅ Bash scripts support `--instance` flag
  - ✅ PowerShell scripts support `-Instance` parameter
  - ✅ Isolated conversation history per instance
  - ✅ Separate Docker containers per instance
  - ✅ Independent configuration volumes
  - ✅ Container naming: `claude-PROJECT-INSTANCE`

### Documentation Hooks
- **Goal**: Automatically remind Claude to document changes according to best practices
- **Implementation**: Pre-tool-use hooks that trigger on edit/create operations
- **Features**:
  - Remind to update conversation files
  - Prompt for feature documentation
  - Encourage progress markers (✅ 🔄 ❌)
- **Status**: Not started

## Medium Priority

### Dynamic Auto-Rebuild Detection
- **Goal**: Detect changes in ANY relevant file and trigger rebuild automatically
- **Current**: Only monitors Dockerfile
- **Enhancement**: Monitor all files referenced in COPY commands, package.json, etc.
- **Benefits**: Ensures container always reflects latest changes
- **Status**: Not started

### Script Unification ✅
- **Goal**: Merge `run-claude.sh` and `run-claude-no-ports.sh` into single script
- **Implementation**: Add `--forward-ports` flag (default: no ports exposed)
- **Benefits**:
  - Single codebase to maintain
  - More secure default (no ports)
  - Cleaner user experience
- **Breaking Change**: Default behavior will change to no port forwarding
- **Status**: COMPLETED
  - ✅ Created `run-claude-unified.sh` with `--forward-ports` flag
  - ✅ Created `run-claude-unified.ps1` with `-ForwardPorts` parameter
  - ✅ Secure default: no ports exposed unless explicitly requested
  - ✅ All existing functionality preserved (fresh, resume, instance support)
  - ✅ Updated README with unified script documentation
  - 🔄 Legacy scripts maintained for backward compatibility

## Low Priority

### Performance Improvements
- **Goal**: Optimize Docker build and startup times
- **Ideas**:
  - Multi-stage builds
  - Better layer caching
  - Prebuilt base images

### Enhanced Session Management
- **Goal**: Better conversation resumption and selection
- **Ideas**:
  - Interactive conversation picker
  - Conversation metadata display
  - Archive old conversations

### Cross-Platform Improvements
- **Goal**: Better Windows/WSL/Linux compatibility
- **Ideas**:
  - Path handling improvements
  - Docker Desktop integration
  - Native PowerShell Core support

---

## Completed Features

✅ **Version Display System** - Shows version in scripts and Claude welcome screen
✅ **Working Persistence** - Conversations and auth persist across runs
✅ **Basic Auto-Rebuild** - Rebuilds when Dockerfile changes
✅ **Global Configuration** - Consistent Claude behavior across projects
✅ **Multi-Instance Support** - Named instances for parallel development
✅ **Script Unification** - Unified scripts with secure defaults (no ports unless requested)
