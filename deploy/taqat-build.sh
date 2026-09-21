#!/usr/bin/env bash
set -Eeuo pipefail

TARGET="${DEPLOY_TARGET:-api}"

case "$TARGET" in
  web)
    echo "==> Building EduBridge Web..."
    cd edubridge-web
    : "${VITE_API_URL:?VITE_API_URL must be set for the web deployment}"
    npm run build
    ;;
  api)
    echo "==> Preparing EduBridge API..."
    cd edubridge-api-laravel
    mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    ;;
  *)
    echo "Unsupported DEPLOY_TARGET: $TARGET" >&2
    exit 2
    ;;
esac
