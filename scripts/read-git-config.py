#!/usr/bin/env python3

from pathlib import Path
import sys
import yaml


ROOT = Path(__file__).resolve().parent.parent
CONFIG_FILE = ROOT / "config" / "git.yml"


def normalize_value(value: object) -> str:
    if isinstance(value, bool):
        return str(value).lower()

    if isinstance(value, (str, int, float)):
        return str(value)

    raise ValueError(f"Unsupported Git config value type: {type(value).__name__}")


def load_git_settings(config_file: Path) -> dict[str, str]:
    if not config_file.exists():
        raise FileNotFoundError(f"Missing Git configuration file: {config_file}")

    with config_file.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)

    if not isinstance(data, dict):
        raise ValueError("git.yml must contain a YAML mapping.")

    git_config = data.get("git")
    if not isinstance(git_config, dict):
        raise ValueError("git.yml must contain a 'git' mapping.")

    settings = git_config.get("settings")
    if not isinstance(settings, dict):
        raise ValueError("git.yml must contain a 'git.settings' mapping.")

    normalized_settings: dict[str, str] = {}

    for key, value in settings.items():
        if not isinstance(key, str):
            raise ValueError("Git config keys must be strings.")

        if not key.strip():
            raise ValueError("Git config keys must not be empty.")

        normalized_settings[key] = normalize_value(value)

    return normalized_settings


def main() -> int:
    try:
        settings = load_git_settings(CONFIG_FILE)
    except (FileNotFoundError, ValueError, yaml.YAMLError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    for key in sorted(settings):
        print(f"{key}\t{settings[key]}")

    return 0


if __name__ == "__main__":
    sys.exit(main())