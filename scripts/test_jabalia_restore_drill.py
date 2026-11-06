"""Integration-style command safety checks with synthetic archives and fake Docker.

The real production Jabalia DB/API/volumes are never called.
"""
import hashlib
import io
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "deploy/jabalia-isolated-restore-drill.sh"


class JabaliaRestoreDrillCommandTest(unittest.TestCase):
    def make_archive(self, root: Path, name: str, files=None, binary=False) -> Path:
        archive = root / name
        if binary:
            archive.write_bytes(b"synthetic pg_dump placeholder; Docker is mocked")
        else:
            with tarfile.open(archive, "w:gz") as tf:
                marker = tarfile.TarInfo("snapshot")
                marker.type = tarfile.DIRTYPE
                tf.addfile(marker)
                for filename, data in (files or {}).items():
                    item = tarfile.TarInfo("snapshot/" + filename)
                    item.size = len(data)
                    tf.addfile(item, io.BytesIO(data))
        (root / (name + ".sha256")).write_text(hashlib.sha256(archive.read_bytes()).hexdigest())
        return archive

    def run_drill(self, missing=False, corrupt=False, fail_run=False):
        with tempfile.TemporaryDirectory() as location:
            root = Path(location)
            (root / "bin").mkdir()
            backup = self.make_archive(root, "jabalia.dump", binary=True)
            teacher = self.make_archive(root, "teacher.tar.gz", {"doc.pdf": b"test-pdf"})
            admission = self.make_archive(root, "admission.tar.gz", {"medical.pdf": b"test-pdf"})
            if corrupt:
                backup.write_bytes(backup.read_bytes() + b"x")

            fake = root / "bin/docker"
            fake.write_text('''#!/bin/bash
set -eu
printf '%s\\n' "$*" >> "$TEST_DOCKER_LOG"
case "$*" in
  *"run -d"*) [[ "${TEST_DOCKER_FAIL_RUN:-0}" != "1" ]] || exit 17;;
  *"SELECT count(*)"*) echo 1;;
  *"FROM jabalia_teacher_documents"*)
    echo "jabalia-teacher-documents/'''+("missing.pdf" if missing else "doc.pdf")+'''"
    ;;
  *"FROM jabalia_admission_documents"*)
    echo "jabalia-admission-documents/medical.pdf"
    ;;
esac
exit 0
''')
            fake.chmod(0o755)
            log = root / "docker-calls.txt"
            env = dict(os.environ, PATH=str(root / "bin") + os.pathsep + os.environ["PATH"],
                       TEST_DOCKER_LOG=str(log), TEST_DOCKER_FAIL_RUN="1" if fail_run else "0",
                       JABALIA_DRILL_STAGE_ROOT=str(root))
            result = subprocess.run([
                "bash", str(SCRIPT), "--db", str(backup),
                "--teachers", str(teacher), "--admissions", str(admission),
            ], env=env, capture_output=True, text=True, timeout=40)
            return result, log.read_text() if log.exists() else ""

    def test_offline_drill_restores_only_a_disposable_database_and_cleans_up(self):
        result, log = self.run_drill()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("database restored in an offline", result.stdout)
        self.assertIn("--network none", log)
        self.assertIn("--pull never", log)
        self.assertIn("--tmpfs /var/lib/postgresql/data", log)
        self.assertIn("createdb -U postgres jabalia_restore_drill", log)
        self.assertIn("rm -f jabalia-restore-drill-", log)
        for live in ["edubridge-jabalia-postgres", "edubridge-jabalia-api", "edubridge-postgres"]:
            self.assertNotIn(live, log)

    def test_broken_reference_fails_and_disposes_of_offline_container(self):
        result, log = self.run_drill(missing=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("database attachment references missing", result.stderr)
        self.assertIn("rm -f jabalia-restore-drill-", log)
        self.assertNotIn("missing.pdf", result.stderr)

    def test_failed_disposable_container_start_does_not_delete_a_preexisting_container(self):
        result, log = self.run_drill(fail_run=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("run -d", log)
        self.assertNotIn("rm -f jabalia-restore-drill-", log)

    def test_bad_checksum_aborts_before_starting_docker(self):
        result, log = self.run_drill(corrupt=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SHA256 verification failed", result.stderr)
        self.assertEqual(log, "")


if __name__ == "__main__":
    unittest.main()
