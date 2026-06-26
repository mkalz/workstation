#!/usr/bin/env python3

from pathlib import Path
import sys
import yaml


ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config"
SUPPORTED_SUFFIXES = {".yml", ".yaml"}


def find_yaml_files(config_dir: Path) -> list[Path]:
    if not config_dir.exists():
        raise FileNotFoundError(f"Missing configuration directory: {config_dir}")

    if not config_dir.is_dir():
        raise NotADirectoryError(f"Configuration path is not a directory: {config_dir}")

    yaml_files = [
        path
        for path in config_dir.rglob("*")
        if path.is_file() and path.suffix in SUPPORTED_SUFFIXES
    ]

    return sorted(yaml_files)


def validate_yaml_file(path: Path) -> list[str]:
    errors = []

    try:
        with path.open("r", encoding="utf-8") as file:
            yaml.safe_load(file)
    except yaml.YAMLError as error:
        errors.append(f"{path}: invalid YAML: {error}")
    except UnicodeDecodeError as error:
        errors.append(f"{path}: invalid UTF-8: {error}")

    return errors


def validate_config_directory(config_dir: Path) -> list[str]:
    errors = []

    try:
        yaml_files = find_yaml_files(config_dir)
    except (FileNotFoundError, NotADirectoryError) as error:
        return [str(error)]

    for yaml_file in yaml_files:
        errors.extend(validate_yaml_file(yaml_file))

    return errors


def main() -> int:
    errors = validate_config_directory(CONFIG_DIR)

    if errors:
        print("Configuration validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Configuration files are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())