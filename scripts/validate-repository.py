#!/usr/bin/env python3

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent

FORBIDDEN_TRACKED_PATHS = {
    ".DS_Store",
}

FORBIDDEN_TRACKED_PREFIXES = (
    ".venv/",
    "__pycache__/",
    ".pytest_cache/",
    ".mypy_cache/",
    ".ruff_cache/",
)

FORBIDDEN_TRACKED_SUFFIXES = (
    "/.DS_Store",
    ".pyc",
    ".pyo",
    ".log",
)

FORBIDDEN_TRACKED_SUBSTRINGS = (
    "/__pycache__/",
)


def list_tracked_files(root: Path) -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=root,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def is_forbidden_tracked_file(path: str) -> bool:
    if path in FORBIDDEN_TRACKED_PATHS:
        return True

    if path.startswith(FORBIDDEN_TRACKED_PREFIXES):
        return True

    if path.endswith(FORBIDDEN_TRACKED_SUFFIXES):
        return True

    return any(substring in path for substring in FORBIDDEN_TRACKED_SUBSTRINGS)


def validate_tracked_files(tracked_files: list[str]) -> list[str]:
    errors = []

    for path in sorted(tracked_files):
        if is_forbidden_tracked_file(path):
            errors.append(f"Forbidden tracked file: {path}")

    return errors


def main() -> int:
    try:
        tracked_files = list_tracked_files(ROOT)
    except subprocess.CalledProcessError as error:
        print("Repository validation failed:", file=sys.stderr)
        print(error.stderr, file=sys.stderr)
        return 1

    errors = validate_tracked_files(tracked_files)

    if errors:
        print("Repository hygiene validation failed:")
        for error in errors:
            print(f"- {error}")
        print()
        print("Remove these files from Git tracking, for example:")
        print("  git rm --cached <path>")
        return 1

    print("Repository hygiene is valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())