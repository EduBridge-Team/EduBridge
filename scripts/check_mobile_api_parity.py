#!/usr/bin/env python3
"""Fail CI when Flutter API calls point at missing Laravel routes.

This is intentionally a static contract check. It does not replace integration
tests, but it catches the common regression where a mobile service method is
added or renamed without a matching backend route.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_LIB = ROOT / "edubridge-app/lib"
LARAVEL_ROUTES = ROOT / "edubridge-api-laravel/routes/api.php"

CLIENT_CALL_RE = re.compile(
    r"""\b(authGet|authPost|authPut|authDelete)\(\s*
        (?:
            '((?:\\.|[^'\\$]|\$(?!\{)|\$\{[^}]*\})*)'
            |
            "((?:\\.|[^"\\$]|\$(?!\{)|\$\{[^}]*\})*)"
        )
    """,
    re.MULTILINE | re.VERBOSE,
)

ROUTE_RE = re.compile(
    r"""Route::(get|post|put|patch|delete)\(\s*(['"])(/[^'"]*)\2""",
    re.MULTILINE,
)

MATCH_RE = re.compile(
    r"""Route::match\(\s*\[([^\]]+)\]\s*,\s*(['"])(/[^'"]*)\2""",
    re.MULTILINE,
)

METHOD_MAP = {
    "authGet": "GET",
    "authPost": "POST",
    "authPut": "PUT",
    "authDelete": "DELETE",
}


def normalize_path(path: str) -> str:
    path = path.split("?", 1)[0]
    path = re.sub(r"\$\{[^}]+\}", "{}", path)
    path = re.sub(r"\$[A-Za-z_][A-Za-z0-9_]*", "{}", path)
    path = re.sub(r"\{[^}/]+\}", "{}", path)
    path = re.sub(r"/+", "/", path)
    if len(path) > 1:
        path = path.rstrip("/")
    return path


def extract_client_calls(text: str) -> set[tuple[str, str]]:
    calls: set[tuple[str, str]] = set()
    for match in CLIENT_CALL_RE.finditer(text):
        path = match.group(2) if match.group(2) is not None else match.group(3)
        if not path.startswith("/"):
            continue
        calls.add((METHOD_MAP[match.group(1)], normalize_path(path)))
    return calls


def extract_backend_routes(text: str) -> set[tuple[str, str]]:
    routes: set[tuple[str, str]] = set()
    for match in ROUTE_RE.finditer(text):
        routes.add((match.group(1).upper(), normalize_path(match.group(3))))

    for match in MATCH_RE.finditer(text):
        methods_raw = match.group(1)
        path = normalize_path(match.group(3))
        for method in re.findall(r"['\"]([A-Za-z]+)['\"]", methods_raw):
            routes.add((method.upper(), path))
    return routes


def main() -> int:
    routes_text = LARAVEL_ROUTES.read_text(encoding="utf-8")

    client_calls: set[tuple[str, str]] = set()
    for dart_file in APP_LIB.rglob("*.dart"):
        client_calls.update(extract_client_calls(dart_file.read_text(encoding="utf-8")))

    backend_routes = extract_backend_routes(routes_text)

    missing = sorted(client_calls - backend_routes)
    if missing:
        print("Mobile API contract check failed. Missing Laravel routes:")
        for method, path in missing:
            print(f"  - {method:6} {path}")
        return 1

    print(
        f"Mobile API contract check passed: "
        f"{len(client_calls)} Flutter calls matched Laravel routes."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
