FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user
RUN useradd -m -s /bin/bash developer
USER developer

WORKDIR /workspace
