# Container Strategy

Containers isolate experiments and long-running services from the host operating system.

The host should remain stable and reproducible.

## Why containers?

Containers provide:

- reproducible environments
- isolated dependencies
- simple upgrades
- easy removal
- minimal impact on the workstation

## What belongs in containers?

Examples include:

- Open WebUI
- JupyterLab
- PostgreSQL
- Redis
- Supabase
- n8n
- Flowise
- AnythingLLM
- SearXNG
- development databases
- MCP servers

## What belongs on the host?

Only stable developer tools.

Examples:

- Homebrew
- Git
- Python
- uv
- R
- Quarto
- Hugo
- Docker Desktop
- VS Code

## Preferred workflow

Host
↓
Docker Desktop
↓
Docker Compose
↓
Application containers

## Repository layout

containers/

    open-webui/

    postgres/

    jupyter/

    ollama/

    n8n/

    flowise/

Each service should contain:

- compose.yaml
- README.md
- optional configuration
- example environment file

## Data persistence

Persistent data should be stored in Docker volumes.

Application configuration should remain inside the repository whenever possible.

## Networking

Containers should communicate over dedicated Docker networks.

Avoid exposing unnecessary ports to the host.

## Updates

Update strategy:

1. Pull latest image.
2. Restart container.
3. Verify with doctor checks.
4. Roll back if required.

## Future direction

Long-term goal:

A new workstation should be able to start all local infrastructure with:

```bash
docker compose up -d
```

without additional manual configuration.