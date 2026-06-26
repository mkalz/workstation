#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
READER = ROOT / "scripts" / "read-git-config.py"


def load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_name}: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


read_git_config_module = load_module("read_git_config", READER)


class GitConfigTests(unittest.TestCase):
    def test_load_git_settings_returns_normalized_settings(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "git.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "git:",
                        "  settings:",
                        "    init.defaultBranch: main",
                        "    fetch.prune: true",
                        "    example.number: 1",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            settings = read_git_config_module.load_git_settings(config_file)

            self.assertEqual(
                settings,
                {
                    "init.defaultBranch": "main",
                    "fetch.prune": "true",
                    "example.number": "1",
                },
            )

    def test_missing_git_mapping_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "git.yml"
            config_file.write_text("settings: {}\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "git.yml must contain a 'git' mapping."):
                read_git_config_module.load_git_settings(config_file)

    def test_missing_settings_mapping_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "git.yml"
            config_file.write_text("git: {}\n", encoding="utf-8")

            with self.assertRaisesRegex(
                ValueError,
                "git.yml must contain a 'git.settings' mapping.",
            ):
                read_git_config_module.load_git_settings(config_file)

    def test_unsupported_value_type_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "git.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "git:",
                        "  settings:",
                        "    invalid.value:",
                        "      nested: true",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Unsupported Git config value type"):
                read_git_config_module.load_git_settings(config_file)

    def test_empty_key_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_file = Path(temporary_directory) / "git.yml"
            config_file.write_text(
                "\n".join(
                    [
                        "git:",
                        "  settings:",
                        "    ? ''",
                        "    : value",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Git config keys must not be empty."):
                read_git_config_module.load_git_settings(config_file)


if __name__ == "__main__":
    unittest.main()