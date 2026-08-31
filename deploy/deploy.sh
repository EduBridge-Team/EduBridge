#!/usr/bin/env bash
# ============================================================
# نشر EduBridge على الاستضافة من الجوال (عبر SSH / Termius)
# يشغّل: ترقية قاعدة البيانات + مسح إعدادات Laravel + نشر الموقع
# الاستخدام على الخادم:
#   cd ~/EduBridge && git pull && bash deploy/deploy.sh
# ============================================================
set -e

# جذر المشروع = مجلد هذا السكربت الأب
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API="$ROOT/edubridge-api-laravel"
PUBLIC="$API/public"
WEB_BUILD="$ROOT/deploy/web"

echo "==> جذر المشروع: $ROOT"

# 1) ترقية قاعدة البيانات (آمنة وقابلة للتكرار — IF NOT EXISTS)
echo "==> (1/3) ترقية قاعدة البيانات..."
cd "$API"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_parent_features.sql')); echo 'db-ok';"

# 2) مسح إعدادات Laravel المؤقتة (config + routes + cache) حتى تُحمَّل المسارات الجديدة
echo "==> (2/3) مسح إعدادات Laravel والمسارات..."
php artisan config:clear
php artisan route:clear
php artisan cache:clear

# 3) نشر ملفات الموقع الجاهزة إلى public
echo "==> (3/3) نشر الموقع..."
cp -r "$WEB_BUILD/assets" "$PUBLIC/"
cp "$WEB_BUILD/icon.png" "$PUBLIC/"
cp "$WEB_BUILD/app.html" "$PUBLIC/app.html"
# ملفات مساعدة (اختيارية — نتجاهل غيابها)
for f in favicon.svg logo.png icons.svg; do
  [ -f "$WEB_BUILD/$f" ] && cp "$WEB_BUILD/$f" "$PUBLIC/" || true
done

echo "==> ✅ تم النشر. افتح https://edubridge.alwaysdata.net واعمل Ctrl+Shift+R"
