# Workstation Design Principles

This document captures the long-term principles that guide this repository.

The goal is not to optimize a single installation, but to build a workstation that remains understandable, reproducible, and maintainable over many years.

---

## 1. The workstation is infrastructure

The workstation itself is not a project.

Projects come and go.

The workstation should remain stable.

---

## 2. Keep the host clean

The operating system should contain only software that is used regularly.

Avoid accumulating experiments, temporary tools, and project-specific dependencies.

---

## 3. Reproducibility over convenience

Every important decision should be reproducible.

Manual configuration should be minimized and documented.

---

## 4. Project-local environments

Python projects use `uv`.

R projects should use `renv` where appropriate.

Dependencies belong to projects—not to the operating system.

---

## 5. Containers for services

Long-running services and experimental software belong in Docker containers.

Examples include:

- JupyterLab
- Open WebUI
- PostgreSQL
- Redis
- n8n
- Home Assistant development tools

---

## 6. One source of truth

The `Brewfile` is the authoritative list of host software.

It is maintained manually.

---

## 7. Simplicity over automation

Automation is valuable only when it reduces complexity.

If an automation becomes harder to understand than the manual process, it should be reconsidered.

---

## 8. Documentation is part of the system

Every important architectural decision should be documented.

Future-you should understand not only *what* was done, but *why* it was done.

---

## 9. Secrets remain local

Secrets are never committed.

Examples:

- SSH private keys
- API keys
- passwords
- certificates

Configuration templates may be versioned, but never credentials.

---

## 10. Continuous improvement

The repository is expected to evolve.

Small, well-documented improvements are preferred over large redesigns.