#!/usr/bin/env bash
# Redeploy trigger for Taqat custom-domain refresh.
set -Eeuo pipefail

TARGET="${DEPLOY_TARGET:-api}"

case "$TARGET" in
  web)
    cd edubridge-web
    : "${PORT:=8080}"
    echo "==> Starting EduBridge Web on 0.0.0.0:$PORT ..."
    exec npm run preview -- --host 0.0.0.0 --port "$PORT"
    ;;
  api)
    exec bash deploy/taqat-api-start.sh
    ;;
  *)
    echo "Unsupported DEPLOY_TARGET: $TARGET" >&2
    exit 2
    ;;
esac
