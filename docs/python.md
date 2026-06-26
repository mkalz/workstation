# Python Strategy

Python on the host is infrastructure, not a project environment.

## Principles

- Use Homebrew Python on the host.
- Use `uv` for project-local environments.
- Do not install global Python packages with `pip`.
- Do not use Anaconda, Miniconda, or pyenv for the default workstation setup.
- Keep experiments inside project directories or containers.

## Recommended project pattern

```sh
mkdir my-project
cd my-project

uv init
uv add pandas matplotlib
uv run python main.py