# Changelog

All notable changes to the Claude Sandbox project will be documented in this file.

## [v1.4.0] - 2025-07-22

### Added
- Version display system - shows version in scripts and Claude Code welcome screen
- VERSION file with version information and feature summary
- Version display in all run scripts (Bash and PowerShell)
- Version information in Docker container startup

### Fixed
- Restored working persistence by reverting timestamp-based container naming
- Container naming now consistent: `claude-$PROJECT_NAME` (no timestamps)
- Conversations and authorization now persist properly across runs

### Changed
- Reset repository to last working state before timestamp commits
- Moved problematic timestamp commits to `abandoned/timestamps` branch

### Known Limitations
- Multi-instance support not yet implemented (containers use consistent naming)
- Concurrent runs of same project will conflict

---

## Previous Versions

Earlier versions focused on:
- Global documentation protocol
- Auto-rebuild detection
- Port forwarding options
- Session management improvements

## v1.3.1 - 2025-07-22
### Fixed
- **CRITICAL**: Fixed auto-rebuild detection not working due to incorrect regex pattern for COPY commands with --chown flags
- **CRITICAL**: Fixed session resumption fallback - now properly starts fresh when no conversations to resume
- Fixed volume mount issue causing Claude Code configuration to be lost
- Fixed container naming causing persistence issues (removed timestamps for consistent naming)

### Changed
- Improved regex pattern to properly parse Dockerfile COPY commands with flags
- Enhanced startup script to restore Claude Code configuration if missing due to volume mount override

## v1.3.0 - 2025-07-21
### Added
- Dynamic file detection - automatically monitors files referenced in Dockerfile COPY commands
- Flexible argument parsing supporting multiple flag combinations
- Port forwarding control with `--forward-ports` / `-ForwardPorts` flag

### Changed
- **BREAKING**: Consolidated duplicate scripts - removed `run-claude-no-ports.*` variants
- **BREAKING**: Default behavior now runs without port forwarding (more secure)
- **BREAKING**: Flag renamed from `--redirect-ports` to `--forward-ports` for clarity
- Improved maintainability with single codebase instead of duplicated logic

### Removed
- `run-claude-no-ports.sh` and `run-claude-no-ports.ps1` (functionality moved to main scripts)

## v1.2.0 - 2025-07-21
### Added
- Documentation hooks for continuous reminder during development
- Version tracking and display during startup
- Enhanced multi-instance support with unique container names
- Optimized hook system following performance guidelines

### Changed
- Simplified hook messages for better token efficiency
- Removed external hook script dependencies
- Improved startup banner with version information

## v1.1.0 - 2025-07-20
### Added
- Smart auto-rebuild detection based on Dockerfile timestamps
- Global documentation protocol with external configuration files
- Multiple run script variants (PowerShell and Bash)
- Support for running multiple container instances simultaneously

### Changed
- Externalized configuration from inline Dockerfile content
- Enhanced file structure with proper .dockerignore

## v1.0.0 - 2025-07-20
### Added
- Initial Claude Code Docker sandbox
- Python 3.12 and Node.js 20 runtime environment
- Basic project structure and run scripts
- Volume persistence for conversations and configuration
