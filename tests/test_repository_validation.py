#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
VALIDATOR = ROOT / "scripts" / "validate-repository.py"


def load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_name}: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_repository_module = load_module("validate_repository", VALIDATOR)


class RepositoryValidationTests(unittest.TestCase):
    def test_allowed_files_have_no_errors(self):
        tracked_files = [
            "README.md",
            "Makefile",
            "scripts/validate-repository.py",
            "config/applications.yml",
        ]

        errors = validate_repository_module.validate_tracked_files(tracked_files)

        self.assertEqual(errors, [])

    def test_ds_store_is_forbidden_at_root(self):
        tracked_files = [
            ".DS_Store",
        ]

        errors = validate_repository_module.validate_tracked_files(tracked_files)

        self.assertEqual(errors, ["Forbidden tracked file: .DS_Store"])

    def test_ds_store_is_forbidden_in_subdirectory(self):
        tracked_files = [
            "docs/.DS_Store",
        ]

        errors = validate_repository_module.validate_tracked_files(tracked_files)

        self.assertEqual(errors, ["Forbidden tracked file: docs/.DS_Store"])

    def test_virtual_environment_is_forbidden(self):
        tracked_files = [
            ".venv/bin/python",
        ]

        errors = validate_repository_module.validate_tracked_files(tracked_files)

        self.assertEqual(errors, ["Forbidden tracked file: .venv/bin/python"])

    def test_python_cache_is_forbidden(self):
        tracked_files = [
            "scripts/__pycache__/validate-config.cpython-313.pyc",
        ]

        errors = validate_repository_module.validate_tracked_files(tracked_files)

        self.assertEqual(
            errors,
            [
                "Forbidden tracked file: scripts/__pycache__/validate-config.cpython-313.pyc",
            ],
        )

    def test_log_files_are_forbidden(self):
        tracked_files = [
            "logs/bootstrap.log",
        ]

        errors = validate_repository_module.validate_tracked_files(tracked_files)

        self.assertEqual(errors, ["Forbidden tracked file: logs/bootstrap.log"])


if __name__ == "__main__":
    unittest.main()