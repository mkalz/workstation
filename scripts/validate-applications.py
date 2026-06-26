#!/usr/bin/env python3

from pathlib import Path
import re
import sys

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required.")
    print("Install with:")
    print("    uv tool install pyyaml")
    sys.exit(1)


ROOT = Path(__file__).resolve().parent.parent

BREWFILE = ROOT / "Brewfile"
APPLICATIONS = ROOT / "config" / "applications.yml"


def parse_brewfile():
    """Return all casks declared in Brewfile."""
    casks = set()

    if not BREWFILE.exists():
        raise FileNotFoundError(BREWFILE)

    pattern = re.compile(r'cask\s+"([^"]+)"')

    with BREWFILE.open() as f:
        for line in f:
            m = pattern.search(line)
            if m:
                casks.add(m.group(1))

    return casks


def parse_manifest():
    """Return all cask packages from applications.yml."""
    if not APPLICATIONS.exists():
        raise FileNotFoundError(APPLICATIONS)

    with APPLICATIONS.open() as f:
        data = yaml.safe_load(f)

    packages = []

    for app in data.get("applications", []):
        if app.get("type") == "cask":
            packages.append(app["package"])

    return packages


def main():
    brew_casks = parse_brewfile()
    manifest = parse_manifest()

    ok = True

    print("Validating application manifest")
    print("--------------------------------")

    duplicates = sorted(
        {p for p in manifest if manifest.count(p) > 1}
    )

    if duplicates:
        ok = False
        print("\nDuplicate packages:")
        for d in duplicates:
            print(f"  - {d}")

    missing = sorted(
        set(manifest) - brew_casks
    )

    if missing:
        ok = False
        print("\nMissing from Brewfile:")
        for m in missing:
            print(f"  - {m}")

    unused = sorted(
        brew_casks - set(manifest)
    )

    if unused:
        print("\nPresent in Brewfile only:")
        for u in unused:
            print(f"  - {u}")

    if ok:
        print("\n✓ Manifest is consistent.")
        sys.exit(0)

    sys.exit(1)


if __name__ == "__main__":
    main()