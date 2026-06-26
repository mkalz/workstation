# Workstation Architecture

This repository defines a reproducible workstation for academic work, software development, publishing, and AI-assisted workflows.

It is not intended to mirror an existing Mac. It defines a clean target state for a new Apple Silicon workstation.

## Core idea

The workstation is infrastructure.

The host operating system should remain stable, minimal, and predictable. Projects, experiments, prototypes, notebooks, databases, and unstable services should run outside the host system whenever possible.

## Design principles

### 1. Keep the host clean

The host should contain only stable tools that are used regularly.

Examples:

- Homebrew
- Git
- GitHub CLI
- Python
- uv
- R
- Quarto
- Hugo
- Docker
- VS Code
- Zotero
- RStudio

### 2. Avoid global project dependencies

The host should not accumulate global Python packages, local notebooks, experimental AI tools, or project-specific libraries.

Python projects should use `uv` and project-local environments.

R projects should use project-local dependency management where appropriate, for example `renv`.

### 3. Prefer containers for experiments

Experimental or service-like tools should run in Docker containers.

Examples:

- JupyterLab
- Open WebUI
- PostgreSQL test instances
- local AI services
- dashboards
- automation experiments

### 4. One source of truth for host software

The `Brewfile` is the source of truth for host-level software.

It should be curated manually and not generated from another configuration format.

### 5. Small bootstrap

The bootstrap process should remain simple.

It should:

1. install or activate Homebrew,
2. install software from the `Brewfile`,
3. run `doctor.sh`.

It should not configure Apple ID, iCloud, browser logins, mail accounts, SSH private keys, or secrets.

### 6. Secrets stay local

Secrets must never be committed.

Examples:

- API keys
- SSH private keys
- tokens
- passwords
- local credentials

A later `.env.example` may document required variables without values.

## Repository structure

```text
workstation/
├── README.md
├── LICENSE
├── .gitignore
├── Brewfile
├── bootstrap.sh
├── doctor.sh
│
├── docs/
│   ├── architecture.md
│   ├── python.md
│   ├── containers.md
│   ├── security.md
│   └── roadmap.md
│
├── install/
├── inventory/
├── config/
├── scripts/
└── tests/