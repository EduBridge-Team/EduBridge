#!/usr/bin/env bash
set -Eeuo pipefail

# Taqat/Nixpacks may not expose DEPLOY_TARGET/VITE_API_URL during image build.
# Always prepare both applications, then let deploy/taqat-start.sh select the
# runtime target using DEPLOY_TARGET.

WEB_API_URL="/api"

# Persist the source revision inside the image so runtime logs can prove exactly
# which Git commit Taqat deployed. Fall back to common CI variables when the
# build context does not include .git.
BUILD_COMMIT="$(git rev-parse --short=12 HEAD 2>/dev/null || true)"
if [[ -z "$BUILD_COMMIT" ]]; then
  BUILD_COMMIT="${SOURCE_VERSION:-${GIT_COMMIT:-${COMMIT_SHA:-unknown}}}"
fi
printf '%s\n' "$BUILD_COMMIT" > .edubridge-build-commit
echo "==> EduBridge build commit: $BUILD_COMMIT"

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
