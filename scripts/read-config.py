#!/usr/bin/env python3

from pathlib import Path
import sys
import yaml


ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config"


def normalize_scalar(value: object) -> str:
    if isinstance(value, bool):
        return str(value).lower()

    if isinstance(value, (str, int, float)):
        return str(value)

    raise ValueError(f"Unsupported scalar value type: {type(value).__name__}")


def load_config_file(section: str, config_dir: Path = CONFIG_DIR) -> dict:
    config_file = config_dir / f"{section}.yml"

    if not config_file.exists():
        raise FileNotFoundError(f"Missing configuration file: {config_file}")

    with config_file.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)

    if not isinstance(data, dict):
        raise ValueError(f"{config_file.name} must contain a YAML mapping.")

    section_data = data.get(section)
    if not isinstance(section_data, dict):
        raise ValueError(f"{config_file.name} must contain a '{section}' mapping.")

    return section_data


def read_config_path(section: str, path: list[str], config_dir: Path = CONFIG_DIR) -> object:
    value: object = load_config_file(section, config_dir)

    for key in path:
        if not isinstance(value, dict):
            raise ValueError(f"Cannot descend into non-mapping value at '{key}'.")

        if key not in value:
            raise ValueError(f"Missing configuration key: {section}.{'.'.join(path)}")

        value = value[key]

    return value


def format_value(value: object) -> list[str]:
    if isinstance(value, list):
        return [normalize_scalar(item) for item in value]

    if isinstance(value, dict):
        lines = []
        for key in sorted(value):
            if not isinstance(key, str):
                raise ValueError("Configuration mapping keys must be strings.")
            lines.append(f"{key}\t{normalize_scalar(value[key])}")
        return lines

    return [normalize_scalar(value)]


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: read-config.py <section> <path...>", file=sys.stderr)
        return 1

    section = sys.argv[1]
    path = sys.argv[2:]

    try:
        value = read_config_path(section, path)
        for line in format_value(value):
            print(line)
    except (FileNotFoundError, ValueError, yaml.YAMLError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())