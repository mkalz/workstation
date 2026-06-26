#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
VALIDATOR = ROOT / "scripts" / "validate-config.py"


def load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_name}: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_config_module = load_module("validate_config", VALIDATOR)


class ConfigValidationTests(unittest.TestCase):
    def test_find_yaml_files_returns_supported_files_only(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            yaml_file = config_dir / "applications.yml"
            yml_nested_dir = config_dir / "nested"
            yml_nested_dir.mkdir()
            nested_yaml_file = yml_nested_dir / "defaults.yaml"
            ignored_file = config_dir / "README.md"

            yaml_file.write_text("applications: []\n", encoding="utf-8")
            nested_yaml_file.write_text("defaults: {}\n", encoding="utf-8")
            ignored_file.write_text("# ignored\n", encoding="utf-8")

            yaml_files = validate_config_module.find_yaml_files(config_dir)

            self.assertEqual(
                yaml_files,
                [
                    yaml_file,
                    nested_yaml_file,
                ],
            )

    def test_missing_config_directory_is_reported(self):
        missing_dir = Path("/tmp/workstation-config-directory-that-should-not-exist")

        errors = validate_config_module.validate_config_directory(missing_dir)

        self.assertEqual(
            errors,
            [f"Missing configuration directory: {missing_dir}"],
        )

    def test_invalid_yaml_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            invalid_yaml = config_dir / "broken.yml"
            invalid_yaml.write_text("applications: [\n", encoding="utf-8")

            errors = validate_config_module.validate_config_directory(config_dir)

            self.assertEqual(len(errors), 1)
            self.assertIn("invalid YAML", errors[0])
            self.assertIn(str(invalid_yaml), errors[0])

    def test_valid_yaml_directory_has_no_errors(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            config_dir = Path(temporary_directory)
            applications = config_dir / "applications.yml"
            defaults = config_dir / "defaults.yaml"

            applications.write_text("applications: []\n", encoding="utf-8")
            defaults.write_text("defaults:\n  finder: true\n", encoding="utf-8")

            errors = validate_config_module.validate_config_directory(config_dir)

            self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()