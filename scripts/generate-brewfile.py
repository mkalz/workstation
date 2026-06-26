#!/usr/bin/env python3

from pathlib import Path
import sys
import yaml

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "config" / "applications.yml"
BREWFILE = ROOT / "Brewfile"


def load_manifest() -> list[dict]:
    if not MANIFEST.exists():
        raise FileNotFoundError(f"Missing manifest: {MANIFEST}")

    with MANIFEST.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    applications = data.get("applications", [])
    if not isinstance(applications, list):
        raise ValueError("applications.yml must contain a list named 'applications'.")

    return applications


def generate_brewfile(applications: list[dict]) -> str:
    formulae = []
    casks = []
    mas_apps = []

    for app in applications:
        app_type = app.get("type")

        if app_type == "formula":
            formulae.append(app["package"])
        elif app_type == "cask":
            casks.append(app["package"])
        elif app_type == "mas":
            mas_apps.append((app["name"], app["id"]))
        elif app_type == "manual":
            continue
        else:
            raise ValueError(f"Unsupported application type: {app_type}")

    lines = [
        "# Workstation Brewfile",
        "# Generated from config/applications.yml.",
        "# Do not edit manually.",
        "",
    ]

    if formulae:
        lines.extend([
            "# --------------------------------------------------------------------",
            "# Formulae",
            "# --------------------------------------------------------------------",
        ])
        for package in formulae:
            lines.append(f'brew "{package}"')
        lines.append("")

    if casks:
        lines.extend([
            "# --------------------------------------------------------------------",
            "# Casks",
            "# --------------------------------------------------------------------",
        ])
        for package in casks:
            lines.append(f'cask "{package}"')
        lines.append("")

    if mas_apps:
        lines.extend([
            "# --------------------------------------------------------------------",
            "# Mac App Store",
            "# --------------------------------------------------------------------",
        ])
        for name, app_id in mas_apps:
            lines.append(f'mas "{name}", id: {app_id}')
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    applications = load_manifest()
    content = generate_brewfile(applications)
    BREWFILE.write_text(content, encoding="utf-8")
    print(f"Generated {BREWFILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())