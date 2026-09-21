#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API="$ROOT/edubridge-api-laravel"

cd "$API"

: "${PORT:=8080}"

mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chmod -R ug+rwX storage bootstrap/cache || true

echo "==> Clearing stale Laravel caches..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo "==> Running Laravel migrations..."
php artisan migrate --force

echo "==> Applying EduBridge idempotent database upgrades..."
for sql in   database/upgrade_parent_features.sql   database/upgrade_board_cards.sql   database/upgrade_conversations.sql   database/upgrade_user_settings.sql   database/upgrade_child_accessibility_profiles.sql   database/upgrade_therapy_requests.sql   database/upgrade_lesson_media.sql   database/upgrade_specialist_workflow.sql   database/upgrade_therapy_sessions.sql   database/upgrade_homework_reports.sql   database/upgrade_care_case_discussions.sql   database/upgrade_final_mobile_parity.sql
do
  if [ -f "$sql" ]; then
    php artisan tinker --execute="DB::unprepared(file_get_contents('$sql')); echo 'applied: $sql';"
  fi
done

echo "==> Starting EduBridge API on 0.0.0.0:$PORT ..."
exec php artisan serve --host=0.0.0.0 --port="$PORT"
