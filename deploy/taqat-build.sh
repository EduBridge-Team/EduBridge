#!/usr/bin/env bash
set -Eeuo pipefail

# Taqat/Nixpacks may not expose DEPLOY_TARGET/VITE_API_URL during image build.
# Always prepare both applications, then let deploy/taqat-start.sh select the
# runtime target using DEPLOY_TARGET.

WEB_API_URL="${VITE_API_URL:-https://api.edubridge.win}"

echo "==> Building EduBridge Web..."
(
  cd edubridge-web

  # Be self-contained even if a platform skips the custom install phase.
  if [[ ! -d node_modules ]]; then
    npm ci --include=dev
  fi

  VITE_API_URL="$WEB_API_URL" npm run build
)

echo "==> Preparing EduBridge API..."
(
  cd edubridge-api-laravel
  mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
  php artisan config:clear
  php artisan route:clear
  php artisan view:clear
)
