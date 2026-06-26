#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
READER = ROOT / "scripts" / "read-config.py"


def load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_name}: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


read_config_module = load_module("read_config", READER)


class ReadConfigTests(unittest.TestCase):
    def test_reads_list_value(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            config_file = config_dir / "vscode.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "vscode:",
                        "  extensions:",
                        "    - redhat.vscode-yaml",
                        "    - ms-python.python",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            value = read_config_module.read_config_path(
                "vscode",
                ["extensions"],
                config_dir,
            )

            self.assertEqual(
                read_config_module.format_value(value),
                [
                    "redhat.vscode-yaml",
                    "ms-python.python",
                ],
            )

    def test_reads_mapping_value_as_tab_separated_lines(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            config_file = config_dir / "git.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "git:",
                        "  settings:",
                        "    init.defaultBranch: main",
                        "    fetch.prune: true",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            value = read_config_module.read_config_path(
                "git",
                ["settings"],
                config_dir,
            )

            self.assertEqual(
                read_config_module.format_value(value),
                [
                    "fetch.prune\ttrue",
                    "init.defaultBranch\tmain",
                ],
            )

    def test_missing_section_mapping_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            config_file = config_dir / "vscode.yml"
            config_file.write_text("extensions: []\n", encoding="utf-8")

            with self.assertRaisesRegex(
                ValueError,
                "vscode.yml must contain a 'vscode' mapping.",
            ):
                read_config_module.read_config_path(
                    "vscode",
                    ["extensions"],
                    config_dir,
                )

    def test_missing_key_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            config_file = config_dir / "vscode.yml"
            config_file.write_text("vscode: {}\n", encoding="utf-8")

            with self.assertRaisesRegex(
                ValueError,
                "Missing configuration key: vscode.extensions",
            ):
                read_config_module.read_config_path(
                    "vscode",
                    ["extensions"],
                    config_dir,
                )

    def test_unsupported_list_item_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            config_file = config_dir / "vscode.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "vscode:",
                        "  extensions:",
                        "    - nested: true",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            value = read_config_module.read_config_path(
                "vscode",
                ["extensions"],
                config_dir,
            )

            with self.assertRaisesRegex(ValueError, "Unsupported scalar value type"):
                read_config_module.format_value(value)


if __name__ == "__main__":
    unittest.main()