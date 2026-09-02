FROM python:3.11-slim

# Install system deps + Node.js
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install --no-cache-dir uv

# Clone and install Google Workspace MCP
WORKDIR /app/google-mcp
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
# Pinned to upstream v1.25.2. The unpinned clone meant every rebuild silently
# adopted whatever HEAD was that day, so the image drifted without a decision
# and builds were not reproducible.
# Pinned by commit SHA rather than tag: the v1.25.2 tag object is malformed
# ("is not a commit"), and cloning it checks out an empty working tree.
ARG GOOGLE_MCP_REF=ce1a9ec4b688c5b43f7fce46eed9abfdbc9c2ef8
RUN git init -q . \
    && git remote add origin https://github.com/taylorwilsdon/google_workspace_mcp.git \
    && git fetch --depth 1 -q origin "$GOOGLE_MCP_REF" \
    && git checkout -q FETCH_HEAD \
    && uv sync --frozen --no-dev --extra disk

# Install Node.js OAuth proxy
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY server.js ./

# Create credentials directory
RUN mkdir -p /app/credentials && chmod 777 /app/credentials

EXPOSE 3000

CMD ["node", "server.js"]
