#!/bin/bash

# Restore Claude Code configuration if it doesn't exist (volume mount issue)
if [ ! -d /home/developer/.config/claude-code ]; then
    echo "Initializing Claude Code configuration..."
    mkdir -p /home/developer/.config/claude-code
fi

# Copy settings if missing (gets wiped by volume mount)
if [ ! -f /home/developer/.config/claude-code/settings.json ]; then
    echo "Restoring Claude Code settings..."
    cat > /home/developer/.config/claude-code/settings.json << 'SETTINGS_EOF'
{
  "global_instructions_file": "/home/developer/.claude-global-instructions.md",
  "auto_create_conversations_dir": true,
  "default_documentation_mode": true,
  "conversation_file_template": "conversations/{feature_name}.md",
  "misc_changes_file": "conversations/misc_changes.md",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write|CreateFile",
        "hooks": [
          {
            "type": "command",
            "command": "echo '📋 Document this change in conversation files'"
          }
        ]
      },
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo '📚 Remember to document tool usage appropriately'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "echo '📝 Session ended - ensure documentation is complete'"
      }
    ],
    "Notification": [
      {
        "type": "command",
        "command": "echo '🔔 Documentation protocol active for this session'"
      }
    ]
  }
}
SETTINGS_EOF
fi

# Load version information
if [ -f /home/developer/VERSION ]; then
    source /home/developer/VERSION
else
    CLAUDE_SANDBOX_VERSION="unknown"
    CLAUDE_SANDBOX_BUILD_DATE="unknown"
    CLAUDE_SANDBOX_FEATURES="basic functionality"
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
echo "================================================================"
echo "🔧 CLAUDE SANDBOX ${CLAUDE_SANDBOX_VERSION} - GLOBAL DOCUMENTATION PROTOCOL"
echo "Built: ${CLAUDE_SANDBOX_BUILD_DATE}"
echo "Features: ${CLAUDE_SANDBOX_FEATURES}"
echo "================================================================"
echo ""
echo "📋 REMINDER: You MUST follow these documentation rules:"
echo "   1. Create conversation files for ALL substantial features"
echo "      Format: conversations/[feature_name].md"
echo "   2. Use status markers: ✅ Complete, 🔄 In Progress, ❌ Not Started"
echo "   3. Document progress CONTINUOUSLY during implementation"
echo "   4. Update status markers after each implementation step"
echo "   5. Use conversations/misc_changes.md for smaller edits"
echo ""
echo "📁 File structure:"
echo "   • Conversations directory: /workspace/conversations/"
echo "   • Global instructions: /home/developer/.claude-global-instructions.md"
echo "   • Project instructions: /workspace/CLAUDE.md"
echo ""
echo "⚠️  IMPORTANT: Start each session by acknowledging these rules!"
echo "================================================================"
echo ""

# Final reminder hook for Claude
echo "🤖 CLAUDE: Please start by confirming you understand and will follow"
echo "    the documentation protocol shown above. Create conversation files"
echo "    for substantial work and update progress markers continuously."
echo ""
