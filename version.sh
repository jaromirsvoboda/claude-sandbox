#!/bin/bash

# Claude Sandbox Version Information Script

if [ -f /home/developer/VERSION ]; then
    source /home/developer/VERSION
    echo "Claude Sandbox ${CLAUDE_SANDBOX_VERSION}"
    echo "Built: ${CLAUDE_SANDBOX_BUILD_DATE}"
    echo "Features: ${CLAUDE_SANDBOX_FEATURES}"
else
    echo "Version information not available"
fi
