FROM python:3.11-slim AS python-base

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
RUN git clone --depth 1 https://github.com/taylorwilsdon/google_workspace_mcp.git . \
    && uv sync --frozen --no-dev --extra disk

# Install Node.js OAuth proxy
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

COPY server.js ./

# Create credentials directory
RUN mkdir -p /app/credentials && chmod 777 /app/credentials

EXPOSE 3000

CMD ["node", "server.js"]
