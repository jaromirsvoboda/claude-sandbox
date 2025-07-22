FROM python:3.12-slim

# Install dependencies including newer Node.js
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user
RUN useradd -m -s /bin/bash developer

# Create global Claude configuration and instructions
USER developer
RUN mkdir -p /home/developer/.config/claude-code

# Copy global Claude instructions and configuration files
COPY --chown=developer:developer .claude-global-instructions.md /home/developer/.claude-global-instructions.md
COPY --chown=developer:developer claude-code-settings.json /home/developer/.config/claude-code/settings.json
COPY --chown=developer:developer claude-startup.sh /home/developer/.claude-startup.sh
COPY --chown=developer:developer VERSION /home/developer/VERSION
COPY --chown=developer:developer version.sh /home/developer/version.sh

# Make startup scripts executable
RUN chmod +x /home/developer/.claude-startup.sh
RUN chmod +x /home/developer/version.sh

USER developer
WORKDIR /workspace
