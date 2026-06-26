#!/usr/bin/env python3

from pathlib import Path
import sys
import yaml

from generate_brewfile import generate_brewfile, load_manifest

ROOT = Path(__file__).resolve().parent.parent
BREWFILE = ROOT / "Brewfile"


def validate_manifest(applications: list[dict]) -> list[str]:
    errors = []
    seen = set()

    for index, app in enumerate(applications, start=1):
        name = app.get("name")
        app_type = app.get("type")

        if not name:
            errors.append(f"Entry {index}: missing name.")

        if app_type not in {"formula", "cask", "mas", "manual"}:
            errors.append(f"Entry {index}: unsupported type '{app_type}'.")

        if app_type in {"formula", "cask"} and not app.get("package"):
            errors.append(f"Entry {index}: {app_type} entry requires package.")

        if app_type == "mas" and not app.get("id"):
            errors.append(f"Entry {index}: mas entry requires id.")

        key = (app_type, app.get("package") or app.get("id") or name)
        if key in seen:
            errors.append(f"Entry {index}: duplicate application entry {key}.")
        seen.add(key)

    return errors


def main() -> int:
    applications = load_manifest()
    errors = validate_manifest(applications)

    expected_brewfile = generate_brewfile(applications)

    if not BREWFILE.exists():
        errors.append("Brewfile does not exist. Run: make generate-brewfile")
    else:
        actual_brewfile = BREWFILE.read_text(encoding="utf-8")
        if actual_brewfile != expected_brewfile:
            errors.append("Brewfile is out of sync. Run: make generate-brewfile")

    if errors:
        print("Application validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Application manifest is valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())