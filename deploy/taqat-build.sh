#!/usr/bin/env bash
set -Eeuo pipefail

# Taqat/Nixpacks may not expose DEPLOY_TARGET/VITE_API_URL during image build.
# Always prepare both applications, then let deploy/taqat-start.sh select the
# runtime target using DEPLOY_TARGET.

WEB_API_URL="/api"

# Nixpacks builds from a Docker context without .git, so a Git SHA may be
# unavailable. Generate a deterministic fingerprint from the deployable source
# tree instead. This changes whenever relevant application/deploy files change.
BUILD_FINGERPRINT="$(
  find edubridge-web edubridge-api-laravel edubridge-app deploy \
    -type f \
    ! -path '*/node_modules/*' \
    ! -path '*/vendor/*' \
    ! -path '*/dist/*' \
    ! -path '*/build/*' \
    -print0 \
  | sort -z \
  | xargs -0 sha256sum \
  | sha256sum \
  | cut -c1-12
)"
printf '%s\n' "$BUILD_FINGERPRINT" > .edubridge-build-fingerprint
echo "==> EduBridge build fingerprint: $BUILD_FINGERPRINT"

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
