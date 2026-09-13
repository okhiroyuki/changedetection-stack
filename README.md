# changedetection-stack

Self-hosted [changedetection.io](https://changedetection.io) stack for monitoring web page changes, running on Docker Compose with a Playwright (browserless Chromium) fetcher for JavaScript-rendered pages.

## Services

| Service | Image | Description |
|---|---|---|
| changedetection | `ghcr.io/dgtlmoon/changedetection.io:latest` | Web UI and monitoring engine |
| playwright-chrome | `ghcr.io/browserless/chromium` | Headless Chromium for fetching JS-heavy pages |

## Requirements

- [OrbStack](https://orbstack.dev/) or Docker Desktop for Mac

## Setup

```bash
docker compose up -d
```

The web UI is available at <http://127.0.0.1:5050>.

> Port 5050 is used instead of the default 5000 to avoid a conflict with AirPlay Receiver on macOS.

## Managing watches as code

Watches are defined in `watches.yaml` and synced to changedetection.io via its REST API.

1. Enable API access and copy the API key from **Settings > API** in the web UI.
2. Install dependencies: `brew install yq jq`
3. Sync:

```bash
export CD_API_KEY="your-api-key"
./scripts/sync-watches.sh
```

The script creates watches that exist only in `watches.yaml`, updates changed ones, and deletes watches that were removed from the YAML.

## Updating

```bash
docker compose pull
docker compose up -d
```

## Notes

- Data is persisted in the `changedetection-data` Docker volume.
- Notifications (Slack, LINE, email, etc.) can be configured in the UI via [Apprise](https://github.com/caronc/apprise).
- The stack binds to `127.0.0.1` only. Expose it behind a reverse proxy with authentication if remote access is needed.
