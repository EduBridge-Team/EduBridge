#!/usr/bin/env bash
set -Eeuo pipefail

# Taqat/Nixpacks does not reliably expose runtime environment variables during
# the image build. Install dependencies for both deploy targets so the same
# repository image can be used safely for either the web or API service.

echo "==> Installing EduBridge Web dependencies..."
(
  cd edubridge-web
  npm ci --include=dev
)

echo "==> Installing EduBridge API dependencies..."
(
  cd edubridge-api-laravel
  composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction
)
