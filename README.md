# google-workspace-mcp

OAuth 2.1 proxy for [google_workspace_mcp](https://github.com/taylorwilsdon/google_workspace_mcp), making it compatible with [Claude.ai](https://claude.ai) remote connectors and scheduled tasks.

`google_workspace_mcp` provides comprehensive Google Workspace access (Gmail, Drive, Calendar, Docs, Sheets, and more), but lacks OAuth 2.1 authentication for Claude.ai connectors. This project wraps it with OAuth 2.1 + Streamable HTTP in a single Docker image.

## Features

- **120+ Google Workspace tools**: Gmail, Drive, Calendar, Docs, Sheets, Slides, Forms, Chat, Tasks, Contacts, Apps Script, Custom Search
- **OAuth 2.1**: Fixed client credentials — works with Claude.ai connectors and scheduled tasks
- **Dynamic tool discovery**: New tools from upstream updates appear automatically
- **Single Docker image**: Both OAuth proxy and Google Workspace MCP backend in one container

## Prerequisites

You need Google Cloud OAuth credentials:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project (or use an existing one)
3. Enable the APIs you need (Gmail, Calendar, Drive, Docs, Sheets, etc.)
4. Go to **APIs & Services > OAuth consent screen** — configure as "External", add your email as a test user
5. Go to **APIs & Services > Credentials > Create Credentials > OAuth Client ID** — type "Web application"
6. Add `http://localhost:8000/oauth2callback` as a redirect URI
7. Download the `client_secret.json`

## Quick Start

### 1. Initial Google OAuth consent (one-time)

Before deploying, run locally to authorize your Google account:

```bash
docker run -it --rm -p 8000:8000 \
  -v $(pwd)/google_creds:/credentials \
  -e GOOGLE_OAUTH_CLIENT_ID="your-client-id" \
  -e GOOGLE_OAUTH_CLIENT_SECRET="your-client-secret" \
  -e USER_GOOGLE_EMAIL="your-email@gmail.com" \
  -e GOOGLE_MCP_CREDENTIALS_DIR=/credentials \
  ghcr.io/taylorwilsdon/google_workspace_mcp:latest \
  "uv run main.py --transport streamable-http --single-user"
```

Call `start_google_auth` via the MCP endpoint to get an authorization URL, complete it in your browser, and the tokens will be saved in `./google_creds/`.

### 2. Deploy with OAuth proxy

```bash
docker run -d \
  -e GOOGLE_OAUTH_CLIENT_ID="your-client-id" \
  -e GOOGLE_OAUTH_CLIENT_SECRET="your-client-secret" \
  -e USER_GOOGLE_EMAIL="your-email@gmail.com" \
  -e GOOGLE_MCP_CREDENTIALS_DIR=/credentials \
  -e MCP_SECRET=your_secret_here \
  -e SERVER_URL=https://your-domain.example.com \
  -v /path/to/client_secret.json:/app/google-mcp/client_secret.json:ro \
  -v /path/to/google_creds:/credentials \
  -p 3000:3000 \
  ghcr.io/afonsofigs/google-workspace-mcp:latest
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MCP_SECRET` | Yes | Secret to derive OAuth credentials (printed on startup) |
| `SERVER_URL` | Yes | Public HTTPS URL (OAuth issuer) |
| `GOOGLE_OAUTH_CLIENT_ID` | Yes | Google Cloud OAuth client ID |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Yes | Google Cloud OAuth client secret |
| `USER_GOOGLE_EMAIL` | Yes | Google account email |
| `GOOGLE_MCP_CREDENTIALS_DIR` | No | Credentials directory (default: `/credentials`) |
| `TOOL_TIER` | No | Tool tier: `core`, `extended`, or `complete` (default: all) |
| `PORT` | No | OAuth proxy port (default: 3000) |
| `BACKEND_PORT` | No | Backend port (default: 8000) |

## Authentication

Same pattern as [obsidian-couchdb-mcp](https://github.com/afonsofigs/obsidian-couchdb-mcp) and [telegram-bot-mcp](https://github.com/afonsofigs/telegram-bot-mcp):

- **Fixed client credentials** derived from `MCP_SECRET` via SHA-256
- **Auto-approve** — no login page; security by fixed credentials
- **PKCE** (S256) mandatory
- **Redirect URIs** limited to `claude.ai` and `claude.com`

## Claude.ai Connector Setup

1. Deploy with HTTPS (e.g., behind Cloudflare Tunnel or reverse proxy)
2. Check logs for `client_id` and `client_secret`
3. Go to [claude.ai/settings/connectors](https://claude.ai/settings/connectors)
4. Add custom connector: URL `https://your-domain.example.com/mcp`
5. Enter `client_id` and `client_secret` from logs

## Architecture

```
Claude.ai / Scheduled Tasks
        |
        v (HTTPS + OAuth 2.1 + Streamable HTTP)
  OAuth proxy :3000 (this project)
        |
        v (HTTP + MCP, localhost)
  google_workspace_mcp :8000 (taylorwilsdon)
        |
        v (Google APIs)
  Gmail, Drive, Calendar, Docs, Sheets, ...
```

## Kubernetes Deployment

See [k8s/deployment.yaml](k8s/deployment.yaml) for an example manifest. You'll need:

- A Secret with your Google OAuth credentials and `MCP_SECRET`
- A PVC to persist the Google OAuth tokens
- A `client_secret.json` mounted from the Secret

## Credits

- [google_workspace_mcp](https://github.com/taylorwilsdon/google_workspace_mcp) — Google Workspace MCP backend
- [obsidian-couchdb-mcp](https://github.com/afonsofigs/obsidian-couchdb-mcp) — OAuth 2.1 proxy pattern
- [telegram-bot-mcp](https://github.com/afonsofigs/telegram-bot-mcp) — OAuth 2.1 pattern

## License

MIT
