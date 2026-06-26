# Workstation

A reproducible Apple Silicon workstation for academic work, software development, publishing, and AI-assisted workflows.

## Philosophy

This repository treats a workstation as infrastructure.

The goal is not to mirror an old Mac, but to define a clean, stable, and reproducible working environment for the coming years.

## Design principles

1. Keep the host clean.
2. Prefer reproducibility over convenience.
3. Use containers for experimental tools and services.
4. Use project-local environments for Python and research code.
5. Avoid global Python packages.
6. Document every major tool and decision.
7. Never commit secrets, tokens, passwords, or private keys.

## Scope

This repository provisions and documents:

- macOS workstation setup
- Homebrew packages and casks
- Python via Homebrew and `uv`
- R and academic publishing tools
- Quarto and Hugo workflows
- Docker-based services
- AI-assisted workflows
- Development tools
- System checks

## Out of scope

This repository does not manage:

- Apple ID
- iCloud
- Mail accounts
- Browser logins
- SSH private keys
- Password manager data
- Personal secrets

## Core strategy

The host system should remain stable and minimal.

Experimental tools, local AI services, notebooks, databases, and unstable software should run in isolated environments such as:

- Docker containers
- project-local `uv` environments
- project-specific R environments

## Roadmap

- [ ] Add project foundation
- [ ] Add Brewfile
- [ ] Add bootstrap script
- [ ] Add doctor checks
- [ ] Add Python setup notes
- [ ] Add R setup notes
- [ ] Add container strategy
- [ ] Add macOS configuration
- [ ] Add documentation for secrets and security