# Claude Sandbox Changelog

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
