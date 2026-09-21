#!/usr/bin/env bash
set -Eeuo pipefail

TARGET="${DEPLOY_TARGET:-api}"

case "$TARGET" in
  web)
    echo "==> Installing EduBridge Web dependencies..."
    cd edubridge-web
    npm ci --include=dev
    ;;
  api)
    echo "==> Installing EduBridge API dependencies..."
    cd edubridge-api-laravel
    composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction
    ;;
  *)
    echo "Unsupported DEPLOY_TARGET: $TARGET" >&2
    exit 2
    ;;
esac
