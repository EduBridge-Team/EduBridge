#!/usr/bin/env bash
# Redeploy trigger for Taqat custom-domain refresh.
set -Eeuo pipefail

TARGET="${DEPLOY_TARGET:-api}"

DEPLOY_FINGERPRINT="unknown"
if [[ -f .edubridge-build-fingerprint ]]; then
  DEPLOY_FINGERPRINT="$(tr -d '\r\n' < .edubridge-build-fingerprint)"
fi

echo "==> EduBridge deployment fingerprint: $DEPLOY_FINGERPRINT"
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
