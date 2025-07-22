#!/bin/bash

# Display version information
if [ -f /home/developer/version.sh ]; then
    source /home/developer/version.sh
fi

# Ensure conversations directory exists in workspace
mkdir -p /workspace/conversations

# Create or update project-level CLAUDE.md to reference global instructions
if [ ! -f /workspace/CLAUDE.md ]; then
    cat > /workspace/CLAUDE.md << 'CLAUDE_EOF'
# Claude Instructions for This Project

This project uses global Claude documentation standards. See `/home/developer/.claude-global-instructions.md` for full protocol.

## Quick Reference
- Feature work: Document in `conversations/[feature_name].md`
- Misc changes: Document in `conversations/misc_changes.md`
- Always use progress markers: ✅ 🔄 ❌
- Update documentation continuously during implementation

## Project-Specific Notes
(Add any project-specific instructions here)
CLAUDE_EOF
fi

# Ensure misc changes file exists
if [ ! -f /workspace/conversations/misc_changes.md ]; then
    cat > /workspace/conversations/misc_changes.md << 'MISC_EOF'
# Miscellaneous Changes Log

## Format
- **Date**: Brief description
- **Reasoning**: Why the change was made
- **Files affected**: List of modified files
- **Status**: ✅ Complete / 🔄 In Progress / ❌ Not Started

---

MISC_EOF
fi

# Display instructions reminder
echo "🔧 Claude Sandbox with Global Documentation Protocol Active"
echo "📁 Conversations directory: /workspace/conversations/"
echo "📋 Global instructions: /home/developer/.claude-global-instructions.md"
echo ""
