#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API="$ROOT/edubridge-api-laravel"

cd "$API"

: "${PORT:=8080}"
export APP_ENV="${APP_ENV:-production}"
export APP_URL="${APP_URL:-https://api.edubridge.win}"

mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chmod -R ug+rwX storage bootstrap/cache || true

echo "==> EduBridge API runtime bootstrap"
echo "==> PHP: $(php -r 'echo PHP_VERSION;')"
echo "==> Working directory: $PWD"
echo "==> Port: $PORT"
echo "==> DB connection: ${DB_CONNECTION:-unset}"
echo "==> DB host: ${DB_HOST:-unset}"
echo "==> APP_ENV: ${APP_ENV:-unset}"
echo "==> APP_URL: ${APP_URL:-unset}"

echo "==> Clearing stale Laravel caches..."
php artisan config:clear || echo "WARNING: config:clear failed; continuing so the container stays inspectable"
php artisan route:clear || echo "WARNING: route:clear failed; continuing so the container stays inspectable"
php artisan view:clear || echo "WARNING: view:clear failed; continuing so the container stays inspectable"

echo "==> Running Laravel migrations..."
if ! php artisan migrate --force; then
  echo "WARNING: Laravel migrations failed. The API will still start so the Taqat terminal/runtime can be inspected."
fi

echo "==> Applying EduBridge idempotent database upgrades..."
for sql in \
  database/upgrade_parent_features.sql \
  database/upgrade_board_cards.sql \
  database/upgrade_conversations.sql \
  database/upgrade_user_settings.sql \
  database/upgrade_child_accessibility_profiles.sql \
  database/upgrade_learning_support_requests.sql \
  database/upgrade_lesson_media.sql \
  database/upgrade_specialist_workflow.sql \
  database/upgrade_learning_support_meetings.sql \
  database/upgrade_homework_reports.sql \
  database/upgrade_care_case_discussions.sql \
  database/upgrade_final_mobile_parity.sql
do
  if [ -f "$sql" ]; then
    echo "==> Applying $sql"
    if ! php artisan tinker --execute="DB::unprepared(file_get_contents('$sql')); echo 'applied: $sql';"; then
      echo "WARNING: $sql failed; continuing so the API can start and be inspected."
    fi
  fi
done

echo "==> Starting EduBridge API on 0.0.0.0:$PORT ..."
exec php artisan serve --host=0.0.0.0 --port="$PORT"
