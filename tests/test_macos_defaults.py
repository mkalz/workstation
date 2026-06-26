#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
READER = ROOT / "scripts" / "read-macos-defaults.py"


def load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_name}: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


read_macos_defaults_module = load_module("read_macos_defaults", READER)


class MacOSDefaultsTests(unittest.TestCase):
    def test_load_macos_defaults_returns_normalized_entries(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "macos.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "macos:",
                        "  defaults:",
                        "    - domain: NSGlobalDomain",
                        "      key: AppleShowAllExtensions",
                        "      type: bool",
                        "      value: true",
                        "    - domain: com.apple.finder",
                        "      key: FXPreferredViewStyle",
                        "      type: string",
                        "      value: Nlsv",
                        "    - domain: example.domain",
                        "      key: ExampleInteger",
                        "      type: int",
                        "      value: 3",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            defaults_entries = read_macos_defaults_module.load_macos_defaults(config_file)

            self.assertEqual(
                defaults_entries,
                [
                    {
                        "domain": "NSGlobalDomain",
                        "key": "AppleShowAllExtensions",
                        "type": "bool",
                        "value": "true",
                    },
                    {
                        "domain": "com.apple.finder",
                        "key": "FXPreferredViewStyle",
                        "type": "string",
                        "value": "Nlsv",
                    },
                    {
                        "domain": "example.domain",
                        "key": "ExampleInteger",
                        "type": "int",
                        "value": "3",
                    },
                ],
            )

    def test_missing_macos_mapping_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "macos.yml"
            config_file.write_text("defaults: []\n", encoding="utf-8")

            with self.assertRaisesRegex(
                ValueError,
                "macos.yml must contain a 'macos' mapping.",
            ):
                read_macos_defaults_module.load_macos_defaults(config_file)

    def test_missing_defaults_list_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "macos.yml"
            config_file.write_text("macos: {}\n", encoding="utf-8")

            with self.assertRaisesRegex(
                ValueError,
                "macos.yml must contain a 'macos.defaults' list.",
            ):
                read_macos_defaults_module.load_macos_defaults(config_file)

    def test_unsupported_type_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "macos.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "macos:",
                        "  defaults:",
                        "    - domain: NSGlobalDomain",
                        "      key: Example",
                        "      type: unsupported",
                        "      value: true",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "unsupported type"):
                read_macos_defaults_module.load_macos_defaults(config_file)

    def test_bool_value_must_be_boolean(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "macos.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "macos:",
                        "  defaults:",
                        "    - domain: NSGlobalDomain",
                        "      key: Example",
                        "      type: bool",
                        "      value: yes",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            entries = read_macos_defaults_module.load_macos_defaults(config_file)

            self.assertEqual(entries[0]["value"], "true")

    def test_string_value_must_be_string(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "macos.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "macos:",
                        "  defaults:",
                        "    - domain: NSGlobalDomain",
                        "      key: Example",
                        "      type: string",
                        "      value: 1",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                ValueError,
                "macOS string defaults require a string value.",
            ):
                read_macos_defaults_module.load_macos_defaults(config_file)


if __name__ == "__main__":
    unittest.main()