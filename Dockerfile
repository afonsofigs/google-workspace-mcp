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
# Pinned to an upstream release. The unpinned clone meant every rebuild
# silently adopted whatever HEAD happened to be that day, so the image drifted
# without a decision and builds were not reproducible.
# Fetched by tag ref rather than `clone --branch`, which fails on these
# annotated tags with "is not a commit" and leaves an empty working tree.
# renovate: datasource=github-releases depName=taylorwilsdon/google_workspace_mcp
ARG GOOGLE_MCP_VERSION=v1.25.2
RUN git init -q . \
    && git remote add origin https://github.com/taylorwilsdon/google_workspace_mcp.git \
    && git fetch --depth 1 -q origin "refs/tags/$GOOGLE_MCP_VERSION" \
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
