"""Offline regression tests for Jabalia's private-file recovery validator.

No live PostgreSQL, production API, or Docker daemon is needed.
"""
import csv
import hashlib
import io
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parent))
from jabalia_restore_reconcile import DrillError, extract_archive, reconcile, verify_checksum


class RestoreReconcileTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def archive(self, entries, name="files.tar.gz"):
        path = self.root / name
        with tarfile.open(path, "w:gz") as tf:
            snapshot = tarfile.TarInfo("snapshot")
            snapshot.type = tarfile.DIRTYPE
            tf.addfile(snapshot)
            for name, blob in entries:
                member = tarfile.TarInfo(name)
                member.size = len(blob)
                tf.addfile(member, io.BytesIO(blob))
        (self.root / (path.name + ".sha256")).write_text(
            hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name + "\n"
        )
        return path

    def refs(self, name, values):
        result = self.root / name
        with result.open("w", newline="") as handle:
            csv.writer(handle).writerows([[value] for value in values])
        return result

    def test_teacher_and_admission_references_match_private_archives(self):
        for category in ["teacher", "admission"]:
            prefix = "jabalia-teacher-documents" if category == "teacher" else "jabalia-admission-documents"
            path = self.archive([("snapshot/secure.pdf", b"testdata")], f"{category}.tar.gz")
            dest = self.root / f"recovered-{category}"
            verify_checksum(path)
            self.assertEqual(extract_archive(path, dest), 1)
            refs, files = reconcile(self.refs(f"{category}.csv", [f"{prefix}/secure.pdf"]), dest, category)
            self.assertEqual((refs, files), (1, 1))

    def test_missing_referenced_file_is_a_failure_without_disclosing_path(self):
        archive = self.archive([])
        dest = self.root / "teacher"
        self.assertEqual(extract_archive(archive, dest), 0)
        csvfile = self.refs("teacher.csv", ["jabalia-teacher-documents/secret-identity.pdf"])
        with self.assertRaisesRegex(DrillError, "1 database attachment references missing"):
            reconcile(csvfile, dest, "teacher")

    def test_empty_snapshot_is_valid_but_not_representative(self):
        archive = self.archive([])
        dest = self.root / "empty"
        self.assertEqual(extract_archive(archive, dest), 0)
        self.assertEqual(reconcile(self.refs("empty.csv", []), dest, "admission"), (0, 0))

    def test_invalid_or_out_of_scope_database_paths_fail_closed(self):
        archive = self.archive([("snapshot/good.pdf", b"test")])
        dest = self.root / "safe"
        extract_archive(archive, dest)
        values = [
            "../escape", "/etc/passwd", "jabalia-teacher-documents/../escape",
            "jabalia-admission-documents/good.pdf", "jabalia-teacher-documents//good.pdf",
        ]
        for index, value in enumerate(values):
            with self.subTest(value=index):
                with self.assertRaises(DrillError):
                    reconcile(self.refs(f"bad-{index}.csv", [value]), dest, "teacher")

    def test_archive_checksum_mismatch_fails(self):
        path = self.archive([])
        path.write_bytes(path.read_bytes() + b"corruption")
        with self.assertRaisesRegex(DrillError, "SHA256 verification failed"):
            verify_checksum(path)

    def test_rejects_tar_traversal_and_symlinks(self):
        for index, target in enumerate(["snapshot/../outside", "/absolute/path"]):
            path = self.archive([(target, b"bad")], f"unsafe-{index}.tar.gz")
            with self.assertRaises(DrillError):
                extract_archive(path, self.root / f"dest-{index}")
        path = self.root / "symlink.tar.gz"
        with tarfile.open(path, "w:gz") as tf:
            directory = tarfile.TarInfo("snapshot")
            directory.type = tarfile.DIRTYPE
            tf.addfile(directory)
            link = tarfile.TarInfo("snapshot/out")
            link.type = tarfile.SYMTYPE
            link.linkname = "/etc/passwd"
            tf.addfile(link)
        (self.root / "symlink.tar.gz.sha256").write_text(hashlib.sha256(path.read_bytes()).hexdigest())
        with self.assertRaises(DrillError):
            extract_archive(path, self.root / "symlink-out")


if __name__ == "__main__":
    unittest.main()
