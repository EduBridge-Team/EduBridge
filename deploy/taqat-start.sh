#!/usr/bin/env bash
# Redeploy trigger for Taqat custom-domain refresh.
set -Eeuo pipefail

TARGET="${DEPLOY_TARGET:-api}"

DEPLOY_COMMIT="unknown"
if [[ -f .edubridge-build-commit ]]; then
  DEPLOY_COMMIT="$(tr -d '\r\n' < .edubridge-build-commit)"
elif command -v git >/dev/null 2>&1; then
  DEPLOY_COMMIT="$(git rev-parse --short=12 HEAD 2>/dev/null || printf 'unknown')"
fi

echo "==> EduBridge deployment commit: $DEPLOY_COMMIT"
echo "==> EduBridge deployment target: $TARGET"

case "$TARGET" in
  web)
    : "${PORT:=8080}"
    echo "==> Starting EduBridge Web on 0.0.0.0:$PORT ..."
    exec node deploy/taqat-web-server.mjs
    ;;
  api)
    exec bash deploy/taqat-api-start.sh
    ;;
  *)
    echo "Unsupported DEPLOY_TARGET: $TARGET" >&2
    exit 2
    ;;
esac
