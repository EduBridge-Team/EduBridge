"""Verify update sequencing and failure stops without touching a server."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'deploy/schools-update.sh'

class SchoolsUpdateTest(unittest.TestCase):
    def run_update(self, failure=''):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'deploy').mkdir()
            (root / 'bin').mkdir()
            (root / 'edubridge-api-laravel').mkdir()
            (root / 'edubridge-api-laravel/.env').touch()
            shutil.copy(SOURCE, root / 'deploy/schools-update.sh')
            (root / 'deploy/check-noor-config.py').write_text('import json,sys; json.load(sys.stdin)\n')
            (root / 'deploy/verify-backup-archive.sh').write_text('exit 0\n')
            (root / 'deploy/oracle-deploy.sh').write_text('echo DEPLOY >> "$TEST_LOG"\n')
            (root / 'bin/git').write_text('''#!/bin/bash
case "$*" in
  *branch*) echo main;;
  *rev-parse*) echo 1234567890123456789012345678901234567890;;
esac
''')
            (root / 'bin/docker').write_text('''#!/bin/bash
set -eu
echo "$*" >> "$TEST_LOG"
if [[ "$*" == *'config --format json'* ]]; then echo '{}'; fi
if [[ "$*" == *'exec edubridge-postgres sh -c'* ]]; then
  [[ "$TEST_FAILURE" != backup ]] || exit 12
  echo archive
fi
if [[ "$*" == *'pg_restore --list'* ]]; then cat >/dev/null; [[ "$TEST_FAILURE" != verify ]] || exit 13; fi
if [[ "$*" == *'compose '* && "$*" == *' build api web'* ]]; then [[ "$TEST_FAILURE" != build ]] || exit 14; fi
if [[ "$*" == *'artisan migrate --force'* ]]; then [[ "$TEST_FAILURE" != migrate ]] || exit 15; fi
exit 0
''')
            for path in (root / 'bin').iterdir():
                path.chmod(0o755)
            log = root / 'commands.log'
            env = dict(os.environ, PATH=str(root / 'bin') + ':' + os.environ['PATH'],
                       EDUBRIDGE_BACKUP_DIR=str(root / 'backups'), TEST_LOG=str(log), TEST_FAILURE=failure)
            result = subprocess.run(['bash', str(root / 'deploy/schools-update.sh'), 'main'],
                                    env=env, text=True, capture_output=True)
            return result.returncode, log.read_text()

    def test_success_backs_up_builds_migrates_then_deploys(self):
        code, commands = self.run_update()
        self.assertEqual(code, 0)
        steps = ['pg_dump', 'pg_restore --list', ' build api web', 'artisan migrate --force', 'DEPLOY', 'artisan migrate:status']
        offsets = [commands.index(step) for step in steps]
        self.assertEqual(offsets, sorted(offsets))

    def test_backup_or_verification_failure_prevents_build_and_migrations(self):
        for failure in ['backup', 'verify']:
            with self.subTest(failure=failure):
                code, commands = self.run_update(failure)
                self.assertNotEqual(code, 0)
                self.assertNotIn(' build api web', commands)
                self.assertNotIn('artisan migrate --force', commands)
                self.assertNotIn('DEPLOY', commands)

    def test_build_or_migration_failure_prevents_application_replacement(self):
        for failure in ['build', 'migrate']:
            with self.subTest(failure=failure):
                code, commands = self.run_update(failure)
                self.assertNotEqual(code, 0)
                self.assertNotIn('DEPLOY', commands)
                if failure == 'build':
                    self.assertNotIn('artisan migrate --force', commands)

if __name__ == '__main__':
    unittest.main()
