#!/bin/bash

# Read version information
if [ -f "/home/developer/VERSION" ]; then
    source /home/developer/VERSION
    echo "🚀 Claude Sandbox ${CLAUDE_SANDBOX_VERSION:-Unknown} (${CLAUDE_SANDBOX_BUILD_DATE:-Unknown})"
    echo "📦 Features: ${CLAUDE_SANDBOX_FEATURES:-N/A}"
    echo ""
else
    echo "🚀 Claude Sandbox (version info not available)"
    echo ""
fi
