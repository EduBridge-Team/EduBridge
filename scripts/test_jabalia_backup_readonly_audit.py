#!/usr/bin/env python3
"""Offline tests for Jabalia read-only recovery evidence audit."""
import datetime as dt
import importlib.util
import os
from pathlib import Path
import stat
import tempfile
import unittest

AUDIT = Path(__file__).with_name("jabalia_backup_readonly_audit.py")
spec = importlib.util.spec_from_file_location("jabalia_backup_readonly_audit", AUDIT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReadonlyAuditTests(unittest.TestCase):
    def test_only_returns_aggregate_not_sensitive_paths(self):
        inventory = [
            {"Path": "private/synthetic-one.dump", "Size": 12, "ModTime": "2026-11-09T04:30:00Z"},
            {"Path": "encrypted/cipher-object", "Size": 8, "ModTime": "2026-11-08T00:00:00+00:00"},
            {"Path": "directory/", "Size": 0, "IsDir": True},
        ]
        result = module.aggregate(inventory)
        self.assertEqual(result, (2, 20, "2026-11-08T00:00:00Z", "2026-11-09T04:30:00Z"))
        self.assertNotIn("synthetic-one", repr(result))

    def test_malformed_size_fails_closed(self):
        with self.assertRaises(ValueError):
            module.aggregate([{"Size": -1, "ModTime": "2026-11-09T00:00:00Z"}])
        with self.assertRaises(ValueError):
            module.aggregate({"data": []})

    def test_missing_and_world_readable_config_flags_review(self):
        with tempfile.TemporaryDirectory() as name:
            p = Path(name) / "test.conf"
            self.assertIn("REVIEW", module.restricted_file_status(p))
            p.write_text("fake config, test only")
            os.chmod(p, 0o600)
            self.assertIn("PRESENT", module.restricted_file_status(p))
            os.chmod(p, 0o644)
            self.assertIn("REVIEW", module.restricted_file_status(p))

    def test_symlink_not_accepted_as_key_export(self):
        with tempfile.TemporaryDirectory() as name:
            path = Path(name) / "key.gpg"
            actual = Path(name) / "actual"
            actual.write_text("synthetic")
            os.chmod(actual, 0o600)
            path.symlink_to(actual)
            self.assertIn("REVIEW", module.restricted_file_status(path))


if __name__ == "__main__":
    unittest.main()
