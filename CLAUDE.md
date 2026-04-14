# CLAUDE.md

## What is this?

OAuth 2.1 proxy for `google_workspace_mcp` (by taylorwilsdon). Adds Claude.ai connector compatibility (OAuth 2.1 + Streamable HTTP) to the Google Workspace MCP backend (which has no auth layer for remote connectors).

Single container runs two processes: our OAuth proxy (:3000) and google_workspace_mcp backend (:8000).

## Architecture

```
Claude.ai (OAuth 2.1 + Streamable HTTP)
  → server.js :3000 (OAuth provider + MCP SDK, tool proxy)
    → google_workspace_mcp :8000 (Python, uv, streamable-http)
      → Google APIs (Gmail, Drive, Calendar, Docs, Sheets, ...)
```

## How it works

1. server.js spawns `uv run main.py` as child process on port 8000
2. On startup, discovers available tools via MCP tools/list call to backend
3. Registers each tool as a proxy in our MCP server (with JSON Schema → Zod conversion)
4. Claude.ai authenticates via OAuth 2.1 → calls our /mcp → we proxy to backend

## Stack

- `google_workspace_mcp` — Python Google Workspace backend (120+ tools, FastMCP, streamable-http)
- `@modelcontextprotocol/sdk` — MCP protocol, OAuth 2.1, Streamable HTTP transport
- `express` + `zod` — HTTP server + schema validation

## Project structure

```
server.js          — OAuth 2.1 provider + tool proxy to backend
package.json       — Dependencies
Dockerfile         — Single container (Python + Node.js, both processes)
k8s/               — Kubernetes deployment template
.github/workflows/ — CI/CD to ghcr.io
```

## Running locally

Requires Google OAuth tokens in `/credentials` (see README for setup):

```bash
npm install
GOOGLE_OAUTH_CLIENT_ID=your-id GOOGLE_OAUTH_CLIENT_SECRET=your-secret \
USER_GOOGLE_EMAIL=your@email.com GOOGLE_MCP_CREDENTIALS_DIR=./creds \
MCP_SECRET=secret SERVER_URL=http://localhost:3000 node server.js
```

Note: The backend (`uv run main.py`) must be available at `/app/google-mcp/`. For local dev, clone `taylorwilsdon/google_workspace_mcp` into that path.

## Key design decisions

- **Proxy, not import** — google_workspace_mcp is Python; our proxy is Node.js. Running it as a child process keeps the stacks separate and allows upstream updates without code changes.
- **Dynamic tool discovery** — Tools are discovered from backend at startup via tools/list, not hardcoded. New tools from upstream updates appear automatically.
- **JSON Schema → Zod** — Backend tool schemas are JSON Schema; our proxy converts them to Zod for the MCP SDK, including nested arrays and objects.
- **runAsUser: 0** — The Dockerfile creates `/app/credentials` with open permissions, but K8s PVCs mount as root. The deployment runs as root to avoid permission issues.

## CI/CD

Push to `main` triggers GitHub Actions → `ghcr.io/afonsofigs/google-workspace-mcp:latest`
