import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "deploy/check-noor-config.py"


class NoorConfigTest(unittest.TestCase):
    def check(self, key=None, model=None, raw=None):
        payload = raw if raw is not None else json.dumps({
            "services": {"api": {"environment": {
                "GROQ_API_KEY": key, "GROQ_MODEL": model,
            }}},
        })
        return subprocess.run(["python3", str(CHECKER)], input=payload,
                              text=True, capture_output=True)

    def test_empty_and_laravel_reserved_values_are_rejected(self):
        for value in (None, "", "   ", "\t", "null", "(null)", "false", "(false)", "empty", "(empty)"):
            with self.subTest(value=value):
                self.assertNotEqual(self.check(value).returncode, 0)

    def test_valid_key_is_not_logged_and_missing_model_is_only_a_warning(self):
        result = self.check("test-only-secret")
        self.assertEqual(result.returncode, 0)
        self.assertIn("WARNING", result.stdout)
        self.assertNotIn("test-only-secret", result.stdout + result.stderr)
        result = self.check("test-only-secret", "openai/gpt-oss-20b")
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("WARNING", result.stdout)

    def test_invalid_configuration_does_not_echo_input(self):
        for raw in ('not-json-test-secret', '{}', '{"services":null}'):
            result = self.check(raw=raw)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn(raw, result.stderr)
            self.assertNotIn("Traceback", result.stderr)

    def test_invalid_key_stops_deployment_before_container_mutations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".env").write_text("# test fixture\n")
            docker = root / "docker"
            docker.write_text("""#!/usr/bin/env bash
if [[ "$*" == "compose version" ]]; then exit 0; fi
if [[ "$*" == *"config --format json" ]]; then
  printf '%s' "$NOOR_TEST_COMPOSE_JSON"
  exit 0
fi
touch "$NOOR_TEST_MUTATION_MARKER"
exit 1
""")
            docker.chmod(0o755)
            marker = root / "mutation"
            environment = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"],
                               EDUBRIDGE_ENV_FILE=str(root / ".env"),
                               NOOR_TEST_MUTATION_MARKER=str(marker))
            for key in ("", "   ", None):
                environment["NOOR_TEST_COMPOSE_JSON"] = json.dumps({
                    "services": {"api": {"environment": {"GROQ_API_KEY": key}}},
                })
                result = subprocess.run(["bash", str(ROOT / "deploy/oracle-deploy.sh")],
                                        env=environment, text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("GROQ_API_KEY", result.stderr)
                self.assertFalse(marker.exists(), "Deployment mutated Docker before validating Noor")

    @unittest.skipUnless(shutil.which("docker"), "Docker Compose is not installed")
    def test_compose_dotenv_interpretation(self):
        # Config resolution only: no image downloads or container operations.
        environment = {key: value for key, value in os.environ.items()
                       if not key.startswith("GROQ_")}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "compose.yml").write_text('services:\n  api:\n    image: alpine\n    env_file: .env\n')
            for assignment, valid in (
                ('GROQ_API_KEY=', False), ('GROQ_API_KEY=""', False),
                ("GROQ_API_KEY=''", False), ('GROQ_API_KEY="   "', False),
                ('GROQ_API_KEY=null', False), ('GROQ_API_KEY=false', False),
                ('GROQ_API_KEY="test-only-secret"', True),
                ("GROQ_API_KEY='test-only-secret'", True),
                ('GROQ_API_KEY = test-only-secret # comment', True),
                ('GROQ_API_KEY=\nGROQ_API_KEY=test-only-secret', True),
            ):
                with self.subTest(assignment=assignment):
                    (root / ".env").write_text(assignment + '\n')
                    resolved = subprocess.run([
                        'docker', 'compose', '--env-file', str(root / '.env'),
                        '-f', str(root / 'compose.yml'), 'config', '--format', 'json',
                    ], text=True, capture_output=True, env=environment)
                    self.assertEqual(resolved.returncode, 0, 'Compose config resolution failed')
                    result = self.check(raw=resolved.stdout)
                    self.assertEqual(result.returncode == 0, valid)
                    self.assertNotIn('test-only-secret', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
