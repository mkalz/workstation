# Workstation

A reproducible macOS workstation setup for academic work, software development, publishing, and AI-assisted workflows.

This repository treats a workstation as infrastructure. The goal is not to clone an old Mac, but to define a clean, stable, and reproducible target state for a new machine.

## Goal

A new Mac should eventually be set up with only a few manual steps:

1. Install Xcode Command Line Tools.
2. Install Homebrew.
3. Clone this repository.
4. Run `make bootstrap`.
5. Complete a small number of manual sign-ins.
6. Start working.

## Scope

This repository manages and documents:

- Homebrew packages, casks, and Mac App Store applications
- application manifest validation
- generated `Brewfile`
- Git configuration
- macOS defaults
- VS Code extensions, user settings, and keybindings
- bootstrap orchestration
- repository validation
- doctor checks
- CI-ready checks

This repository does not manage:

- Apple ID
- iCloud account state
- Mail accounts
- browser logins
- SSH private keys
- password manager data
- API keys
- personal secrets
- private documents

## Repository structure

```text
workstation/
│
├── Brewfile
├── Makefile
├── bootstrap.sh
├── doctor.sh
├── README.md
├── pyproject.toml
│
├── install/
├── config/
├── docs/
├── containers/
├── inventory/
├── scripts/
├── tests/
│
├── .github/
└── .vscode/