#!/usr/bin/env python3
"""Real HTTP test against CI-only restored Laravel/PostgreSQL + private blobs.

No user credentials, JWTs, personally identifying data or file contents are
printed. The static account fixtures exist only in a disposable CI database.
"""
import hashlib
import json
import os
import urllib.error
import urllib.request

if (
    os.environ.get("GITHUB_ACTIONS") != "true"
    or os.environ.get("APP_ENV") != "testing"
    or os.environ.get("JABALIA_RECOVERY_SYNTHETIC") != "1"
    or os.environ.get("DB_HOST") != "127.0.0.1"
    or os.environ.get("DB_DATABASE") != "jabalia_recovery_restored_ci"
):
    raise SystemExit("REFUSED: recovered CI database required")

BASE = "http://127.0.0.1:18891/api"
PASSWORD = "SyntheticRecoveryPass!2026"

def request(method, path, token=None, data=None):
    headers = {"Accept": "application/json"}
    payload = None
    if data is not None:
        payload = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(BASE + path, data=payload, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=12) as response:
            return response.status, response.read(), response.headers
    except urllib.error.HTTPError as error:
        return error.code, error.read(), error.headers

def login(email):
    status, body, _ = request("POST", "/auth/login", data={
        "email": email, "password": PASSWORD
    })
    if status != 200:
        raise AssertionError("synthetic login failed with status " + str(status))
    token = json.loads(body).get("token")
    assert isinstance(token, str) and len(token) > 32
    return token

def expect(method, path, token, allowed, label):
    status, body, headers = request(method, path, token=token)
    if status not in allowed:
        raise AssertionError(f"{label}: unexpected HTTP {status}")
    print(f"PASS: {label}: HTTP {status}")
    return status, body, headers

owner = login("ci-recovery-owner@example.test")
foreign_owner = login("ci-recovery-foreign@example.test")
teacher = login("ci-recovery-teacher@example.test")
parent = login("ci-recovery-parent@example.test")
other_parent = login("ci-recovery-other-parent@example.test")
director = login("ci-recovery-director@example.test")
print("PASS: six synthetic identities authenticated against recovered PostgreSQL")

teacher_path = "/institutions/jabalia/schools/8301/teachers/8103/documents/8601/file"
admission_path = "/parent/children/8401/enrollment-requests/8501/jabalia-documents/8701/file"
director_path = "/school/enrollment-requests/8501/jabalia-documents/8701/file"

teacher_bytes = b"%PDF-1.4\nSYNTHETIC-JABALIA-TEACHER-RECOVERY-ONLY\n%%EOF\n"
admission_bytes = b"%PDF-1.4\nSYNTHETIC-JABALIA-ADMISSION-RECOVERY-ONLY\n%%EOF\n"

_, recovered, headers = expect("GET", teacher_path, owner, {200},
                               "authorized owner recovered teacher attachment")
assert hashlib.sha256(recovered).digest() == hashlib.sha256(teacher_bytes).digest()
assert "no-store" in headers.get("Cache-Control", "")
print("PASS: teacher restored bytes match synthetic source SHA256")
expect("GET", teacher_path, foreign_owner, {403, 404},
       "foreign institution denied teacher file")
expect("GET", teacher_path, teacher, {403, 404},
       "teacher denied personnel file")
expect("GET", teacher_path, None, {401, 403},
       "anonymous denied teacher file")
expect("GET", "/institutions/jabalia/schools/8302/teachers/8103/documents/8601/file",
       owner, {404}, "wrong school denied teacher file")

_, recovered, headers = expect("GET", admission_path, parent, {200},
                               "authorized parent recovered admission attachment")
assert hashlib.sha256(recovered).digest() == hashlib.sha256(admission_bytes).digest()
assert "no-store" in headers.get("Cache-Control", "")
print("PASS: admission restored bytes match synthetic source SHA256")
_, recovered, _ = expect("GET", director_path, director, {200},
                         "active director admitted to recovered synthetic file")
assert hashlib.sha256(recovered).digest() == hashlib.sha256(admission_bytes).digest()
expect("GET", admission_path, other_parent, {404},
       "foreign parent denied admission file")
expect("GET", director_path, teacher, {403, 404},
       "teacher denied admission file")
expect("GET", director_path, None, {401, 403},
       "anonymous denied admission file")
expect("GET", "/school/enrollment-requests/8502/jabalia-documents/8701/file",
       director, {404}, "foreign school/enrollment denied admission file")
print("PASS: authenticated recovered application download and denial checks")
