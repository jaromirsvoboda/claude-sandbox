#!/bin/bash

# Documentation reminder hook script
# This script is called by Claude Code hooks to remind about documentation protocol

HOOK_TYPE="$1"
TOOL_NAME="$2"

case "$HOOK_TYPE" in
    "pre-edit")
        echo "📋 ABOUT TO MODIFY FILES:"
        echo "   • Document this change in appropriate conversation file"
        echo "   • Substantial features → conversations/[feature_name].md"
        echo "   • Small changes → conversations/misc_changes.md"
        echo "   • Use status markers: ✅ 🔄 ❌"
        echo ""
        ;;
    "pre-any-tool")
        echo "💭 PLANNING & DEVELOPMENT REMINDER:"
        echo "   • Document your thinking process in conversation files"
        echo "   • Record decisions, analysis, and reasoning"
        echo "   • Update progress markers as you plan and develop"
        echo "   • Don't wait until implementation - document the journey!"
        echo ""
        ;;
    "post-session")
        echo ""
        echo "📝 RESPONSE COMPLETE REMINDER:"
        echo "   • Have you documented this interaction?"
        echo "   • Update conversation files with:"
        echo "     - Planning thoughts and decisions made"
        echo "     - Analysis and reasoning process"
        echo "     - Next steps and dependencies"
        echo "     - Current progress markers ✅ 🔄 ❌"
        echo ""

        # Check if conversation files exist and suggest updates
        if [ -d "/workspace/conversations" ]; then
            conversation_count=$(find /workspace/conversations -name "*.md" -not -name "misc_changes.md" | wc -l)
            if [ "$conversation_count" -eq 0 ]; then
                echo "⚠️  No feature conversation files found. Consider creating one for substantial discussions/planning."
            else
                echo "✅ Found $conversation_count conversation file(s). Make sure they reflect your latest thinking!"
            fi
        fi
        ;;
    "notification")
        echo "🤖 Claude Code notification - Remember: Document planning AND implementation!"
        ;;
esac
