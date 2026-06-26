#!/usr/bin/env python3

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
GENERATOR = ROOT / "scripts" / "generate-brewfile.py"
VALIDATOR = ROOT / "scripts" / "validate-applications.py"


def load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module {module_name}: {path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


generate_brewfile_module = load_module("generate_brewfile", GENERATOR)
validate_applications_module = load_module("validate_applications", VALIDATOR)


class BrewfileGenerationTests(unittest.TestCase):
    def test_generate_brewfile_groups_supported_application_types(self):
        applications = [
            {
                "name": "Git",
                "type": "formula",
                "package": "git",
            },
            {
                "name": "Visual Studio Code",
                "type": "cask",
                "package": "visual-studio-code",
            },
            {
                "name": "Keynote",
                "type": "mas",
                "id": 409183694,
            },
            {
                "name": "Manual Login Example",
                "type": "manual",
            },
        ]

        brewfile = generate_brewfile_module.generate_brewfile(applications)

        self.assertIn('brew "git"', brewfile)
        self.assertIn('cask "visual-studio-code"', brewfile)
        self.assertIn('mas "Keynote", id: 409183694', brewfile)
        self.assertNotIn("Manual Login Example", brewfile)

    def test_generate_brewfile_is_deterministic(self):
        applications = [
            {
                "name": "Git",
                "type": "formula",
                "package": "git",
            },
            {
                "name": "Python",
                "type": "formula",
                "package": "python@3.13",
            },
        ]

        first = generate_brewfile_module.generate_brewfile(applications)
        second = generate_brewfile_module.generate_brewfile(applications)

        self.assertEqual(first, second)

    def test_generate_brewfile_rejects_unsupported_application_type(self):
        applications = [
            {
                "name": "Unsupported App",
                "type": "unsupported",
                "package": "unsupported",
            },
        ]

        with self.assertRaises(ValueError):
            generate_brewfile_module.generate_brewfile(applications)


class ApplicationValidationTests(unittest.TestCase):
    def test_valid_manifest_has_no_errors(self):
        applications = [
            {
                "name": "Git",
                "type": "formula",
                "package": "git",
            },
            {
                "name": "Visual Studio Code",
                "type": "cask",
                "package": "visual-studio-code",
            },
            {
                "name": "Keynote",
                "type": "mas",
                "id": 409183694,
            },
            {
                "name": "Manual Login Example",
                "type": "manual",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertEqual(errors, [])

    def test_missing_name_is_reported(self):
        applications = [
            {
                "type": "formula",
                "package": "git",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertIn("Entry 1: missing name.", errors)

    def test_formula_without_package_is_reported(self):
        applications = [
            {
                "name": "Git",
                "type": "formula",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertIn("Entry 1: formula entry requires package.", errors)

    def test_cask_without_package_is_reported(self):
        applications = [
            {
                "name": "Visual Studio Code",
                "type": "cask",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertIn("Entry 1: cask entry requires package.", errors)

    def test_mas_without_id_is_reported(self):
        applications = [
            {
                "name": "Keynote",
                "type": "mas",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertIn("Entry 1: mas entry requires id.", errors)

    def test_unsupported_type_is_reported(self):
        applications = [
            {
                "name": "Unsupported App",
                "type": "unsupported",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertIn("Entry 1: unsupported type 'unsupported'.", errors)

    def test_duplicate_formula_package_is_reported(self):
        applications = [
            {
                "name": "Git",
                "type": "formula",
                "package": "git",
            },
            {
                "name": "Git Duplicate",
                "type": "formula",
                "package": "git",
            },
        ]

        errors = validate_applications_module.validate_manifest(applications)

        self.assertIn(
            "Entry 2: duplicate application entry ('formula', 'git').",
            errors,
        )


if __name__ == "__main__":
    unittest.main()