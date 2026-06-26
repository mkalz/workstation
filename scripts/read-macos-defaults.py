#!/usr/bin/env python3

from pathlib import Path
import sys
import yaml


ROOT = Path(__file__).resolve().parent.parent
CONFIG_FILE = ROOT / "config" / "macos.yml"
SUPPORTED_TYPES = {"bool", "int", "float", "string"}


def normalize_value(value_type: str, value: object) -> str:
    if value_type == "bool":
        if not isinstance(value, bool):
            raise ValueError("macOS bool defaults require a boolean value.")
        return str(value).lower()

    if value_type == "int":
        if not isinstance(value, int) or isinstance(value, bool):
            raise ValueError("macOS int defaults require an integer value.")
        return str(value)

    if value_type == "float":
        if not isinstance(value, (int, float)) or isinstance(value, bool):
            raise ValueError("macOS float defaults require a numeric value.")
        return str(value)

    if value_type == "string":
        if not isinstance(value, str):
            raise ValueError("macOS string defaults require a string value.")
        return value

    raise ValueError(f"Unsupported macOS defaults type: {value_type}")


def load_macos_defaults(config_file: Path) -> list[dict[str, str]]:
    if not config_file.exists():
        raise FileNotFoundError(f"Missing macOS configuration file: {config_file}")

    with config_file.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)

    if not isinstance(data, dict):
        raise ValueError("macos.yml must contain a YAML mapping.")

    macos_config = data.get("macos")
    if not isinstance(macos_config, dict):
        raise ValueError("macos.yml must contain a 'macos' mapping.")

    defaults = macos_config.get("defaults")
    if not isinstance(defaults, list):
        raise ValueError("macos.yml must contain a 'macos.defaults' list.")

    normalized_defaults = []

    for index, item in enumerate(defaults, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"macos.defaults entry {index} must be a mapping.")

        domain = item.get("domain")
        key = item.get("key")
        value_type = item.get("type")
        value = item.get("value")

        if not isinstance(domain, str) or not domain.strip():
            raise ValueError(f"macos.defaults entry {index} requires a non-empty domain.")

        if not isinstance(key, str) or not key.strip():
            raise ValueError(f"macos.defaults entry {index} requires a non-empty key.")

        if value_type not in SUPPORTED_TYPES:
            raise ValueError(
                f"macos.defaults entry {index} has unsupported type: {value_type}"
            )

        normalized_defaults.append(
            {
                "domain": domain,
                "key": key,
                "type": value_type,
                "value": normalize_value(value_type, value),
            }
        )

    return normalized_defaults


def main() -> int:
    try:
        defaults_entries = load_macos_defaults(CONFIG_FILE)
    except (FileNotFoundError, ValueError, yaml.YAMLError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    for entry in defaults_entries:
        print(
            "\t".join(
                [
                    entry["domain"],
                    entry["key"],
                    entry["type"],
                    entry["value"],
                ]
            )
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())